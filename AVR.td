//===- AVR.td - Describe the AVR Target Machine ---------*- tblgen -*-==//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source 
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
// This is the top level entry point for the AVR target.
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Target-independent interfaces
//===----------------------------------------------------------------------===//

include "llvm/Target/Target.td"

//===----------------------------------------------------------------------===//
// AVR supported processors.
//===----------------------------------------------------------------------===//
class Proc<string Name, list<SubtargetFeature> Features>
 : Processor<Name, NoItineraries, Features>;

def : Proc<"generic",         []>;

//===----------------------------------------------------------------------===//
// Register File Description
//===----------------------------------------------------------------------===//

include "AVRRegisterInfo.td"

//===----------------------------------------------------------------------===//
// Calling Convention Description
//===----------------------------------------------------------------------===//

//include "AVRCallingConv.td"

//===----------------------------------------------------------------------===//
// Instruction Descriptions
//===----------------------------------------------------------------------===//

//include "AVRInstrInfo.td"

//def AVRInstrInfo : InstrInfo;

//def AVRInstPrinter : AsmWriter {
 // string AsmWriterClassName  = "InstPrinter";
  // bit isMCAsmWriter = 1;
//}

//===----------------------------------------------------------------------===//
// Target Declaration
//===----------------------------------------------------------------------===//

 def AVR : Target {
  //let InstructionSet = AVRInstrInfo;
  //let AssemblyWriters = [AVRInstPrinter];
}

