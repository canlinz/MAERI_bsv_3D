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

interface DN_TopControlPorts;
  method Action putConfig(DN_SubTreeDestBits newConfig);
endinterface 

/* Tier 0: Distribution Network (ChubbyTree) */
interface MAERI_Accelerator_T0_ControlPorts;
    method Bool isReadyForNextConfig;
    interface Vector#(DistributionBandwidth, DN_TopControlPorts) dnControlPorts;
endinterface

interface MAERI_Accelerator_T0;
    interface MAERI_Accelerator_T0_ControlPorts controlPorts;
    interface Vector#(DistributionBandwidth, GI_InputDataPorts) inputDataPorts;
    interface Vector#(NumMultSwitches, GI_OutputDataPorts) dnDataPorts;
endinterface

(* synthesize *)
module mkMAERI_Accelerator_T0(MAERI_Accelerator_T0);
    /* Submodule */
    DN_DistributionNetwork dn <- mkDN_DistributionNetwork;

    /* Interfaces */
    Vector#(DistributionBandwidth, GI_InputDataPorts) inputDataPortsDef;
    for(Integer inPrt = 0; inPrt < valueOf(DistributionBandwidth); inPrt = inPrt + 1) begin
        inputDataPortsDef[inPrt] = 
            interface GI_InputDataPorts
                method Action putData(Data data);
                    dn.inputDataPorts[inPrt].putData(data);
                endmethod
            endinterface;
    end 

    Vector#(NumMultSwitches, GI_OutputDataPorts) dnDataPortsDef;
    for(Integer multSwID = 0; multSwID < valueOf(NumMultSwitches); multSwID = multSwID + 1) begin
        dnDataPortsDef[multSwID] = 
            interface GI_OutputDataPorts
                method ActionValue#(Data) getData;
                    let ret <- dn.outputDataPorts[multSwID].getData;
                    return ret;
                endmethod
            endinterface;
    end

    Vector#(DistributionBandwidth, DN_TopControlPorts) dnControlPortsDef;
    for(Integer prt = 0; prt < valueOf(DistributionBandwidth); prt = prt + 1) begin
        dnControlPortsDef[prt] =
            interface DN_TopControlPorts
                method Action putConfig(DN_SubTreeDestBits newConfig);
                    if(newConfig != dn_topSubtree_nullConfig) begin
                        dn.controlPorts[prt].putConfig(newConfig); 
                    end
                endmethod
            endinterface;
    end

    interface inputDataPorts = inputDataPortsDef;
    interface dnDataPorts = dnDataPortsDef;

    /* Control Interface */
    interface controlPorts = 
        interface MAERI_Accelerator_T0_ControlPorts
            method Bool isReadyForNextConfig;
                return dn.isEmpty;
            endmethod
            interface dnControlPorts = dnControlPortsDef;
        endinterface;

endmodule