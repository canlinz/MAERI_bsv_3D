/******************************************************************************
Copyright (c) 2023 Georgia Instititue of Technology

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

Author: Hyoukjun Kwon (hyoukjun@gatech.edu), Canlin Zhang (canlinz2@gatech.edu)

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

/* Tier 1: Multiplier Network (MS) and Distribution Network (ART) */
interface MAERI_Accelerator_T1_ControlPorts;
    interface MN_MultiplierNetwork_ControlPorts mnControlPorts;
    interface RN_ReductionNetwork_ControlPorts rnControlPorts;
endinterface

interface MAERI_Accelerator_T1;
    interface MAERI_Accelerator_T1_ControlPorts controlPorts;
    interface Vector#(CollectionBandwidth, GI_OutputDataPorts) outputDataPorts;
    interface Vector#(NumMultSwitches, GI_InputDataPorts) mnDataPorts;
endinterface

(* synthesize *)
module mkMAERI_Accelerator_T1(MAERI_Accelerator_T1);
    /* Submodules */
    MN_MultiplierNetwork mn <- mkMN_MultiplierNetwork;
    RN_ReductionNetwork rn <- mkRN_ReductionNetwork;

    /* Interconnect MN and RN */
    for(Integer multSwID = 0; multSwID < valueOf(NumMultSwitches); multSwID = multSwID +1) begin
        mkConnection(mn.dataPorts[multSwID].getData, rn.inputDataPorts[multSwID].putData);
    end

    /* Interfaces */
    /* RN/Accelerator output data ports */
  Vector#(CollectionBandwidth, GI_OutputDataPorts) outputDataPortsDef;
  for(Integer outPrt = 0; outPrt < valueOf(CollectionBandwidth); outPrt = outPrt +1) begin
    outputDataPortsDef[outPrt] =
      interface GI_OutputDataPorts
        method ActionValue#(Data) getData;
          let ret <- rn.outputDataPorts[outPrt].getData;
          return ret;
        endmethod
      endinterface;

  end

    /* Multiplier Switch input data ports */
    Vector#(NumMultSwitches, GI_InputDataPorts) mnDataPortsDef;
    for(Integer multSwID = 0; multSwID < valueOf(NumMultSwitches); multSwID = multSwID + 1) begin
        mnDataPortsDef[multSwID] = 
            interface GI_InputDataPorts
                method Action putData(Data data);
                    mn.dataPorts[multSwID].putData(data);
                endmethod
            endinterface;
    end

    interface mnDataPorts = mnDataPortsDef;
    interface outputDataPorts = outputDataPortsDef;

    // /* Control Ports */
    // TODO: Direct connection or handle controls here? 
    interface controlPorts = 
        interface MAERI_Accelerator_T1_ControlPorts
            interface mnControlPorts = 
                interface MN_MultiplierNetwork_ControlPorts
                    method Action putConfig(MN_Config newConfig, StatData numActualActiveMultSwitches);
                        mn.controlPorts.putConfig(newConfig, numActualActiveMultSwitches);
                    endmethod
                endinterface;

            interface rnControlPorts = 
                interface RN_ReductionNetwork_ControlPorts
                    method Action putConfig(RN_Config newConfig);
                        rn.controlPorts.putConfig(newConfig);
                    endmethod
                endinterface;
        endinterface;

endmodule