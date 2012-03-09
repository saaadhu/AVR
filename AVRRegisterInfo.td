//===- AVRRegisterInfo.td - AVR Register defs ----------*- tblgen -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source 
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
//  Declarations that describe the AVR register file
//===----------------------------------------------------------------------===//

class AVRReg<bits<6> num, string n> : Register<n> {
  field bits<6> Num = num;
  let Namespace = "AVR";
}

class AVRRegWithSubregs<bits<4> num, string n, list<Register> subregs> 
  : RegisterWithSubRegs<n, subregs> {
  field bits<4> Num = num;
  let Namespace = "AVR";
}

//===----------------------------------------------------------------------===//
//  Registers
//===----------------------------------------------------------------------===//

def R0  : AVRReg<0,  "r0">;
def R1  : AVRReg<1,  "r1">;
def R2  : AVRReg<2,  "r2">;
def R3  : AVRReg<3,  "r3">;
def R4  : AVRReg<4,  "r4">;
def R5  : AVRReg<5,  "r5">;
def R6  : AVRReg<6,  "r6">;
def R7  : AVRReg<7,  "r7">;
def R8  : AVRReg<8,  "r8">;
def R9  : AVRReg<9,  "r9">;
def R10 : AVRReg<10, "r10">;
def R11 : AVRReg<11, "r11">;
def R12 : AVRReg<12, "r12">;
def R13 : AVRReg<13, "r13">;
def R14 : AVRReg<14, "r14">;
def R15 : AVRReg<15, "r15">;
def R16 : AVRReg<16, "r16">;
def R17 : AVRReg<17, "r17">;
def R18 : AVRReg<18, "r18">;
def R19 : AVRReg<19, "r19">;
def R20 : AVRReg<20, "r20">;
def R21 : AVRReg<21, "r21">;
def R22 : AVRReg<22, "r22">;
def R23 : AVRReg<23, "r23">;
def R24 : AVRReg<24, "r24">;
def R25 : AVRReg<25, "r25">;
def R26 : AVRReg<26, "r26">;
def R27 : AVRReg<27, "r27">;
def R28 : AVRReg<28, "r28">;
def R29 : AVRReg<29, "r29">;
def R30 : AVRReg<30, "r30">;
def R31 : AVRReg<31, "r31">;

def PC  : AVRReg<32, "pc">;
def SPH : AVRReg<33, "0x3D">;
def SPL : AVRReg<33, "0x3E">;

def subreg_loreg : SubRegIndex { let Namespace = "AVR"; }
def subreg_hireg : SubRegIndex { let Namespace = "AVR"; }

let SubRegIndices = [subreg_hireg, subreg_loreg] in {
def X	: AVRRegWithSubregs<0, "x", [R27, R26]>;
def Y	: AVRRegWithSubregs<1, "y", [R29, R28]>;
def Z	: AVRRegWithSubregs<2, "z", [R31, R30]>;
}


def GR8 : RegisterClass<"AVR", [i8], 8,
   // Volatile registers
  (add R0, R1, R2, R3, R4, R5, R6, R7, R8, R9, R10, R11, R12, R13, R14, R15, R16, R17, R18, R19, R20, R21, R22, R23, R24, R25, R26, R27, R28, R29, R30, R31)>;

def IO8 : RegisterClass<"AVR", [i8], 8,
  (add SPH, SPL)>;

def GR16 : RegisterClass<"AVR", [i16], 16,
   (add PC, X, Y, Z)>
{
  let SubRegClasses = [(GR8 subreg_hireg, subreg_loreg)];
}

