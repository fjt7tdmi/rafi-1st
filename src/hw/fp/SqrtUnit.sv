/*
 * Copyright 2018 Akifumi Fujita
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import BasicTypes::*;
import RvTypes::*;
import Rv32Types::*;

module SqrtUnit #(
    parameter WIDTH = 16
)(
    output logic [WIDTH-1:0] sqrt,
    output logic [WIDTH-1:0] remnant,
    output logic done,
    input logic enable,
    input logic [WIDTH*2-1:0] src,
    input logic clk,
    input logic rst
);

endmodule
