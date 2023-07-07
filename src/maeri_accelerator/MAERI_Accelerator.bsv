/******************************************************************************
Copyright (c) 2019 Georgia Instititue of Technology

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

Author: Hyoukjun Kwon (hyoukjun@gatech.edu)

*******************************************************************************/
import Vector::*;
import Connectable::*;

import AcceleratorConfig::*;
import GenericInterface::*;
import DataTypes::*;
import DN_Types::*;
import MN_Types::*;
import RN_Types::*;
import SU_Types::*;

import DN_DistributionNetwork::*;
import MN_MultiplierNetwork::*;
import RN_ReductionNetwork::*;

import MAERI_Accelerator_T0::*;
import MAERI_Accelerator_T1::*;


interface MAERI_Accelerator_ControlPorts;
  method Bool isReadyForNextConfig;
  interface MN_MultiplierNetwork_ControlPorts mnControlPorts;
  interface RN_ReductionNetwork_ControlPorts rnControlPorts;
  interface Vector#(DistributionBandwidth, DN_TopControlPorts) dnControlPorts;
endinterface


interface MAERI_Accelerator;
  interface MAERI_Accelerator_ControlPorts controlPorts;
  interface Vector#(DistributionBandwidth, GI_InputDataPorts) inputDataPorts;
  interface Vector#(CollectionBandwidth, GI_OutputDataPorts) outputDataPorts;
endinterface

(* synthesize *)
module mkMAERI_Accelerator(MAERI_Accelerator);
  /* Submodules */
  MAERI_Accelerator_T0 t0 <- mkMAERI_Accelerator_T0;
  MAERI_Accelerator_T1 t1 <- mkMAERI_Accelerator_T1;

  /* Interconnect T0 and T1 */
  for(Integer multSwID = 0; multSwID < valueOf(NumMultSwitches); multSwID = multSwID + 1) begin
    mkConnection(t0.dnDataPorts[multSwID].getData, t1.mnDataPorts[multSwID].putData);
  end 

  /* Interface assignment */
  interface inputDataPorts = t0.inputDataPorts;
  interface outputDataPorts = t1.outputDataPorts;

  /* Control Ports */
  interface controlPorts = 
    interface MAERI_Accelerator_ControlPorts
      method Bool isReadyForNextConfig = t0.controlPorts.isReadyForNextConfig;
      interface dnControlPorts = t0.controlPorts.dnControlPorts;
      interface rnControlPorts = t1.controlPorts.rnControlPorts;
      interface mnControlPorts = t1.controlPorts.mnControlPorts;
    endinterface;

endmodule


