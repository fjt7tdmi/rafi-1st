# Copyright 2018 Akifumi Fujita
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import json
import os
import posixpath
import sys

import rafi.riscv_tests

class ModelSimProject(object):
    def __init__(self, name, work, packages, sources):
        self.name = name
        self.work = work
        self.packages = packages
        self.sources = sources

    def make_rule(self):
        packages = " $\n    ".join(self.packages)
        sources = " $\n    ".join(self.sources)
        packages_from_work = " $\n        ".join([posixpath.relpath(package, self.work) for package in self.packages])
        sources_from_work = " $\n        ".join([posixpath.relpath(source, self.work) for source in self.sources])

        return f"""
build {self.work}/{self.name}: vsim_setup {self.work}
    work = {self.work}
    project = {self.name}

build {self.work}/{self.name}/_vmake: vlog $
    {packages} $
    {sources} $
    {self.work}/{self.name}
    project = {self.name}
    work = {self.work}
    srcs = $
        {packages_from_work} $
        {sources_from_work}
"""

class RiscvTestsProject(object):
    def __init__(self, inputs, outputs):
        self.inputs = inputs
        self.outputs = outputs
        self.work = outputs

    def make_rule(self):
        names = rafi.riscv_tests.list_test_names(self.inputs)

        rule = ""
        for name in names:
            rule += f"""
build {self.outputs}/{name}.bin: objcopy $
    {self.inputs}/{name}
    start = 0x80000000
    end   = 0x80008000

build {self.outputs}/{name}.txt: BinaryToText $
    {self.outputs}/{name}.bin
"""
        return rule

def _generate_make_workdir_rule(projects):
    workdirs = set()
    for project in projects:
        workdirs.add(project.work)
    rule = ""
    for path in workdirs:
        rule += f"""
build {path}: mkdir
"""
    return rule

def _normalize_path(root, path):
    return posixpath.normpath(posixpath.join(root, path))

def _parse_metabuild_json_modelsim(path, common, project):
    json_dir = posixpath.dirname(path)

    name = project["name"] if 'name' in project.keys() else common["name"]
    work = project["work"] if 'work' in project.keys() else common["work"]

    packages = []
    if 'packages' in common:
        for package in common["packages"]:
            packages.append(_normalize_path(json_dir, package))
    if 'packages' in project:
        for package in project["packages"]:
            packages.append(_normalize_path(json_dir, package))

    sources = []
    if 'sources' in common:
        for source in common["sources"]:
            sources.append(_normalize_path(json_dir, source))
    if 'sources' in project:
        for source in project["sources"]:
            sources.append(_normalize_path(json_dir, source))

    return ModelSimProject(name, work, packages, sources)

def _parse_metabuild_json_riscv_tests(path, common, project):
    json_dir = posixpath.dirname(path)
    
    inputs = project["inputs"] if 'inputs' in project.keys() else common["inputs"]
    outputs = project["outputs"] if 'outputs' in project.keys() else common["outputs"]

    return RiscvTestsProject(_normalize_path(json_dir, inputs), _normalize_path(json_dir, outputs))

def _parse_metabulid_json(path):
    with open(path, "r") as f:
        j = json.load(f)
        common = j["common"]
        projects = []

        for project in j["projects"]:
            project_type = project["type"] if "type" in project.keys() else common["type"]
            if project_type == "modelsim":
                projects.append(_parse_metabuild_json_modelsim(path, common, project))
            elif project_type == "riscv_tests":
                projects.append(_parse_metabuild_json_riscv_tests(path, common, project))
            else:
                raise f"Unknown type '{project_type}' appeared in metabuild.json"

        return projects

def metabuild(path):
    projects = _parse_metabulid_json(path)

    rule = _generate_make_workdir_rule(projects)
    for project in projects:
        rule += project.make_rule()
    return rule

# Entry point for test
if __name__ == '__main__':
    print(metabuild(sys.argv[1]))