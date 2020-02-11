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

module FpSqrtUnit #(
    parameter EXPONENT_WIDTH = 8,
    parameter FRACTION_WIDTH = 23,
    parameter WIDTH = 1 + EXPONENT_WIDTH + FRACTION_WIDTH
)(
    output logic [WIDTH-1:0] fpResult,
    output fflags_t flags,
    input logic [2:0] roundingMode,
    input logic [WIDTH-1:0] fpSrc,
    input logic clk,
    input logic rst
);

endmodule
