//===- AVRInstrInfo.td - AVR Instruction defs -----------*- tblgen-*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source 
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file describes the AVR instructions in TableGen format.
//
//===----------------------------------------------------------------------===//

include "AVRInstrFormats.td"

//===----------------------------------------------------------------------===//
// Type Constraints.
//===----------------------------------------------------------------------===//
class SDTCisI8<int OpNum> : SDTCisVT<OpNum, i8>;
class SDTCisI16<int OpNum> : SDTCisVT<OpNum, i16>;

//===----------------------------------------------------------------------===//
// Type Profiles.
//===----------------------------------------------------------------------===//
def SDT_AVRCall         : SDTypeProfile<0, -1, [SDTCisVT<0, iPTR>]>;
def SDT_AVRCallSeqStart : SDCallSeqStart<[SDTCisVT<0, i16>]>;
def SDT_AVRCallSeqEnd   : SDCallSeqEnd<[SDTCisVT<0, i16>, SDTCisVT<1, i16>]>;
def SDT_AVRWrapper      : SDTypeProfile<1, 1, [SDTCisSameAs<0, 1>,
                                                  SDTCisPtrTy<0>]>;
def SDT_AVRCmp          : SDTypeProfile<0, 2, [SDTCisSameAs<0, 1>]>;
def SDT_AVRBrCC         : SDTypeProfile<0, 2, [SDTCisVT<0, OtherVT>,
                                                  SDTCisVT<1, i8>]>;
def SDT_AVRSelectCC     : SDTypeProfile<1, 3, [SDTCisSameAs<0, 1>,
                                                  SDTCisSameAs<1, 2>, 
                                                  SDTCisVT<3, i8>]>;
def SDT_AVRShift        : SDTypeProfile<1, 2, [SDTCisSameAs<0, 1>, SDTCisI8<1>, SDTCisI8<0>,
                                                  SDTCisI8<2>]>;

//===----------------------------------------------------------------------===//
// AVR Specific Node Definitions.
//===----------------------------------------------------------------------===//
def AVRretflag  : SDNode<"AVRISD::RET_FLAG", SDTNone,
                       [SDNPHasChain, SDNPOptInGlue]>;
def AVRretiflag : SDNode<"AVRISD::RETI_FLAG", SDTNone,
                       [SDNPHasChain, SDNPOptInGlue]>;

def AVRrlc     : SDNode<"AVRISD::RLC", SDTIntUnaryOp, []>;
def AVRrrc     : SDNode<"AVRISD::RRC", SDTIntUnaryOp, []>;
def AVRshlc    : SDNode<"AVRISD::SHLC", SDTIntUnaryOp, []>;
def AVRsrac    : SDNode<"AVRISD::SRAC", SDTIntUnaryOp, []>;
def AVRsrlc    : SDNode<"AVRISD::SRLC", SDTIntUnaryOp, []>;

def AVRcall    : SDNode<"AVRISD::CALL", SDT_AVRCall,
                     [SDNPHasChain, SDNPOutGlue, SDNPOptInGlue, SDNPVariadic]>;
def AVRcallseq_start :
                 SDNode<"ISD::CALLSEQ_START", SDT_AVRCallSeqStart,
                        [SDNPHasChain, SDNPOutGlue]>;
def AVRcallseq_end :
                 SDNode<"ISD::CALLSEQ_END",   SDT_AVRCallSeqEnd,
                        [SDNPHasChain, SDNPOptInGlue, SDNPOutGlue]>;
def AVRWrapper : SDNode<"AVRISD::Wrapper", SDT_AVRWrapper>;
def AVRcmp     : SDNode<"AVRISD::CMP", SDT_AVRCmp, [SDNPOutGlue]>;
def AVRbrcc    : SDNode<"AVRISD::BR_CC", SDT_AVRBrCC,
                            [SDNPHasChain, SDNPInGlue]>;
def AVRselectcc: SDNode<"AVRISD::SELECT_CC", SDT_AVRSelectCC,
                            [SDNPInGlue]>;
def AVRshl     : SDNode<"AVRISD::SHL", SDT_AVRShift, []>;
def AVRsrl     : SDNode<"AVRISD::SRL", SDT_AVRShift, []>;
def AVRsra     : SDNode<"AVRISD::SRA", SDT_AVRShift, []>;

//===----------------------------------------------------------------------===//
// AVR Operand Definitions.
//===----------------------------------------------------------------------===//

// Address operands
def memsrc : Operand<i16> {
  let PrintMethod = "printSrcMemOperand";
  let MIOperandInfo = (ops GR16, i16imm);
}

def memdst : Operand<i16> {
  let PrintMethod = "printSrcMemOperand";
  let MIOperandInfo = (ops GR16, i16imm);
}

// Short jump targets have OtherVT type and are printed as pcrel imm values.
def jmptarget : Operand<OtherVT> {
  let PrintMethod = "printPCRelImmOperand";
}

// Operand for printing out a condition code.
def cc : Operand<i8> {
  let PrintMethod = "printCCOperand";
}

//===----------------------------------------------------------------------===//
// AVR Complex Pattern Definitions.
//===----------------------------------------------------------------------===//

def addr : ComplexPattern<iPTR, 2, "SelectAddr", [], []>;

//===----------------------------------------------------------------------===//
// Pattern Fragments
def zextloadi16i8 : PatFrag<(ops node:$ptr), (i16 (zextloadi8 node:$ptr))>;
def  extloadi16i8 : PatFrag<(ops node:$ptr), (i16 ( extloadi8 node:$ptr))>;
def and_su : PatFrag<(ops node:$lhs, node:$rhs), (and node:$lhs, node:$rhs), [{
  return N->hasOneUse();
}]>;
//===----------------------------------------------------------------------===//

// Instruction list..

// ADJCALLSTACKDOWN/UP implicitly use/def SP because they may be expanded into
// a stack adjustment and the codegen must know that they may modify the stack
// pointer before prolog-epilog rewriting occurs.
// Pessimistically assume ADJCALLSTACKDOWN / ADJCALLSTACKUP will become
// sub / add which can clobber SRW.
let Defs = [SPH, SPL], Uses = [SPH, SPL] in {
def ADJCALLSTACKDOWN : Pseudo<(outs), (ins i16imm:$amt),
                              "#ADJCALLSTACKDOWN",
                              [(AVRcallseq_start timm:$amt)]>;
def ADJCALLSTACKUP   : Pseudo<(outs), (ins i16imm:$amt1, i16imm:$amt2),
                              "#ADJCALLSTACKUP",
                              [(AVRcallseq_end timm:$amt1, timm:$amt2)]>;
}

let neverHasSideEffects = 1 in
def NOP : Pseudo<(outs), (ins), "nop", []>;
//===----------------------------------------------------------------------===//
//  Control Flow Instructions...
//

// FIXME: Provide proper encoding!
let isReturn = 1, isTerminator = 1, isBarrier = 1 in {
  def RET  : IForm16<0x0, DstReg, SrcPostInc, Size2Bytes,
                     (outs), (ins), "ret",  [(AVRretflag)]>;
  def RETI : II16r<0x0, (outs), (ins), "reti", [(AVRretiflag)]>;
}

let isBranch = 1, isTerminator = 1 in {

// FIXME: expand opcode & cond field for branches!

// Direct branch
let isBarrier = 1 in {
  // Short branch
  def JMP : CJForm<0, 0, (outs), (ins jmptarget:$dst),
                   "jmp\t$dst",
                   [(br bb:$dst)]>;
}

// Conditional branches

let Uses = [SREG] in 
  def JCC : CJForm<0, 0,
                   (outs), (ins jmptarget:$dst, cc:$cc),
                   "br$cc\t$dst",
                   [(AVRbrcc bb:$dst, imm:$cc)]>;
} // isBranch, isTerminator

//===----------------------------------------------------------------------===//
//  Call Instructions...
//
let isCall = 1 in
  // All calls clobber the non-callee saved registers. SPW is marked as
  // a use to prevent stack-pointer assignments that appear immediately
  // before calls from potentially appearing dead. Uses for argument
  // registers are added manually.
  let Defs = [R18, R19, R20, R21, R22, R23, R24, R25, R26, R27, R30, R31],
      Uses = [SPL, SPH] in {
    def CALL     : II16i<0x0,
                          (outs), (ins i16imm:$dst, variable_ops),
                          "call\t$dst", [(AVRcall imm:$dst)]>;
  }


//  IO Instructions
//
def OUT      : I8rr<0x0,
		   (outs IO8:$dst), (ins GR8:$src),
                   "out \t{$dst, $src}",
                    []>;

def IN      : I8rr<0x0,
		   (outs GR8:$dst), (ins IO8:$src),
                   "in \t{$dst, $src}",
                    []>;

//===----------------------------------------------------------------------===//
//  Miscellaneous Instructions...
//
let Defs = [SPH, SPL], Uses = [SPH, SPL], neverHasSideEffects=1 in {
let mayLoad = 1 in
def POP      : II8r<0x0,
                       (outs GR8:$reg), (ins), "pop \t$reg", []>;

let mayStore = 1 in
def PUSH  : II8r<0x0,
                     (outs), (ins GR8:$reg), "push \t$reg",[]>;
}

//===----------------------------------------------------------------------===//
// Move Instructions

// FIXME: Provide proper encoding!
let neverHasSideEffects = 1 in {
def MOV8rr  : I8rr<0x0,
                   (outs GR8:$dst), (ins GR8:$src),
                   "mov \t{$dst, $src}",
                   []>;
def MOV16rr : I16rr<0x0,
                    (outs GR16:$dst), (ins GR16:$src),
                    "movw \t{$dst, $src}",
                    []>;
}

// FIXME: Provide proper encoding!
let isAsCheapAsAMove = 1 in {
def MOV8ri  : I8ri<0x0,
                   (outs IGR8:$dst), (ins i8imm:$src),
                   "ldi\t{$dst, $src}",
                   [(set IGR8:$dst, imm:$src)]>;

}

let canFoldAsLoad = 1, isReMaterializable = 1 in {
def MOV8rm  : I8rm<0x0,
                   (outs GR8:$dst), (ins memsrc:$src),
                   "lds\t{$dst, $src}",
                   [(set GR8:$dst, (load addr:$src))]>;
def MOV16rm : I16rm<0x0,
                    (outs GR16:$dst), (ins memsrc:$src),
                    "lds\t{$dst, $src}",
                    [(set GR16:$dst, (load addr:$src))]>;
}
def MOV8rm_INDEX  : I8rm<0x0,
                   (outs GR8:$dst), (ins memsrc:$src),
                   "ldd\t{$dst, $src}",
                   []>;
def MOV16rm_INDEX : I16rm<0x0,
                    (outs GR16:$dst), (ins memsrc:$src),
                    "lds\t{$dst, $src}",
                    []>;

let mayLoad = 1, hasExtraDefRegAllocReq = 1, Constraints = "$base = $base_wb" in {
def MOV8rm_POST  : IForm8<0x0, DstReg, SrcPostInc, Size2Bytes,
                         (outs GR8:$dst, GR16:$base_wb), (ins GR16:$base),
                         "ldd\t{$dst, @$base+}", []>;
def MOV16rm_POST : IForm16<0x0, DstReg, SrcPostInc, Size2Bytes,
                           (outs GR16:$dst, GR16:$base_wb), (ins GR16:$base),
                           "ldd\t{$dst, @$base+}", []>;
}

/// Any instruction that defines a 8-bit result leaves the high half of the
// register. Truncate can be lowered to EXTRACT_SUBREG, and CopyFromReg may
// be copying from a truncate, but any other 8-bit operation will zero-extend
// up to 16 bits.
def def8 : PatLeaf<(i8 GR8:$src), [{
  return N->getOpcode() != ISD::TRUNCATE &&
         N->getOpcode() != TargetOpcode::EXTRACT_SUBREG &&
         N->getOpcode() != ISD::CopyFromReg;
}]>;

// In the case of a 8-bit def that is known to implicitly zero-extend,
// we can use a SUBREG_TO_REG.
//def : Pat<(i16 (zext def8:$src)),
//          (SUBREG_TO_REG (i16 0), GR8:$src, subreg_8bit)>;


def MOV8mr  : I8mr<0x0,
                   (outs), (ins memdst:$dst, GR8:$src),
                   "sts\t{$dst, $src}",
                   [(store GR8:$src, addr:$dst)]>;
def MOV16mr : I16mr<0x0,
                    (outs), (ins memdst:$dst, GR16:$src),
                    "sts\t{$dst, $src}",
                    [(store GR16:$src, addr:$dst)]>;

def MOV8imr : I8mr<0x0,
                   (outs), (ins INDR16:$dst, GR8:$src),
                   "st\t{$dst, $src}",
                   [(store GR8:$src, addr:$dst)]>;

def MOV8mr_INDEX : I8mr<0x0,
                   (outs), (ins memsrc:$dst, GR8:$src),
                   "std\t{$dst, $src}",
                   []>;

def MOV8mr_POST  : IForm8<0x0, DstMem, SrcPostInc, Size2Bytes,
                         (outs GR8:$dst, GR16:$base_wb), (ins GR16:$base),
                         "std\t{$dst, @$base+}", []>;
def MOV16mr_POST : IForm16<0x0, DstReg, SrcPostInc, Size2Bytes,
                           (outs GR16:$dst, GR16:$base_wb), (ins GR16:$base),
                           "std\t{$dst, @$base+}", []>;

//===----------------------------------------------------------------------===//
// Arithmetic Instructions

let Constraints = "$src = $dst" in {

let Defs = [SREG] in {

let isCommutable = 1 in { // X = ADD Y, Z  == X = ADD Z, Y

def ADD8rr  : I8rr<0x0,
                   (outs GR8:$dst), (ins GR8:$src, GR8:$src2),
                   "add \t{$dst, $src2}",
                   [(set GR8:$dst, (add GR8:$src, GR8:$src2))
                   ]>;


def ADC8rr  : I8rr<0x0,
                   (outs GR8:$dst), (ins GR8:$src, GR8:$src2),
                   "adc\t{$dst, $src2}",
                   [(set GR8:$dst, (adde GR8:$src, GR8:$src2)),
                    (implicit SREG)]>;

}


def SUB8rr  : I8rr<0x0,
                   (outs GR8:$dst), (ins GR8:$src, GR8:$src2),
                   "sbc \t{$dst, $src2}",
                   [(set GR8:$dst, (sub GR8:$src, GR8:$src2))
                   ]>;

def SUB8ri  : I8ri<0x0,
                   (outs GR8:$dst), (ins GR8:$src, i8imm:$src2),
                   "sbci \t{$dst, $src2}",
                   [(set GR8:$dst, (sub GR8:$src, imm:$src2))]>;

def SUB8wri  : I8ri<0x0,
                   (outs IGR8:$dst), (ins IGR8:$src, i8imm:$src2),
                   "sbiw \t{$dst, $src2}",
                   []>;
}

def AND8rr   : I8rr<0x0,
                    (outs GR8:$dst), (ins GR8:$src, GR8:$src2),
                    "and \t{$dst, $src2}",
                    [(set GR8:$dst, (and GR8:$src, GR8:$src2)) ]>;

def AND8ri   : I8ri<0x0,
                    (outs IGR8:$dst), (ins IGR8:$src, i8imm:$src2),
                    "andi \t{$dst, $src2}",
                    [(set IGR8:$dst, (and IGR8:$src, imm:$src2)) ]>;

def OR8rr   : I8ri<0x0,
                    (outs GR8:$dst), (ins GR8:$src, GR8:$src2),
                    "or \t{$dst, $src2}",
                    [(set GR8:$dst, (or GR8:$src, GR8:$src2)) ]>;

def OR8ri   : I8ri<0x0,
                    (outs IGR8:$dst), (ins IGR8:$src, i8imm:$src2),
                    "ori \t{$dst, $src2}",
                    [(set IGR8:$dst, (or IGR8:$src, imm:$src2)) ]>;
def XOR8rr   : I8rr<0x0,
                    (outs GR8:$dst), (ins GR8:$src, GR8:$src2),
                    "eor \t{$dst, $src2}",
                    [(set GR8:$dst, (xor GR8:$src, GR8:$src2)) ]>;
}

// Integer comparisons
let Defs = [SREG] in {
def CMP8rr  : I8rr<0x0,
                   (outs), (ins GR8:$src, GR8:$src2),
                   "cp\t{$src, $src2}",
                   [(AVRcmp GR8:$src, GR8:$src2), (implicit SREG)]>;

def CMP8ri  : I8ri<0x0,
                   (outs), (ins GR8:$src, i8imm:$src2),
                   "cpi\t{$src, $src2}",
                   [(AVRcmp GR8:$src, imm:$src2), (implicit SREG)]>;
}

let usesCustomInserter = 1 in {

  let Defs = [SREG] in {
  def Shl8     : Pseudo<(outs GR8:$dst), (ins GR8:$src, GR8:$cnt),
                        "# Shl8 PSEUDO",
                        [(set GR8:$dst, (AVRshl GR8:$src, GR8:$cnt))]>;


  def Srl8     : Pseudo<(outs GR8:$dst), (ins GR8:$src, GR8:$cnt),
                        "# Srl8 PSEUDO",
                        [(set GR8:$dst, (AVRsrl GR8:$src, GR8:$cnt))]>;

  def Sra8     : Pseudo<(outs GR8:$dst), (ins GR8:$src, GR8:$cnt),
                        "# Sra8 PSEUDO",
                        [(set GR8:$dst, (AVRsra GR8:$src, GR8:$cnt))]>;

  }
}

let Constraints = "$src = $dst" in
{
  def Shl8r1  : I8rr<0x0,
      (outs GR8:$dst), (ins GR8:$src),
      "lsl \t{$dst}",
      [(set GR8:$dst, (AVRshlc GR8:$src))]>;
      
  def Shr8r1  : I8rr<0x0,
      (outs GR8:$dst), (ins GR8:$src),
      "lsr \t{$dst}",
      [(set GR8:$dst, (AVRsrlc GR8:$src))]>;

  def Shr8r1c  : I8rr<0x0,
      (outs GR8:$dst), (ins GR8:$src),
      "asr \t{$dst}",
      [(set GR8:$dst, (AVRsrac GR8:$src))]>;

  def ROL8r1c  : I8rr<0x0,
      (outs GR8:$dst), (ins GR8:$src),
      "rol\t$dst",
      [(set GR8:$dst, (AVRrlc GR8:$src))]>;

  def ROR8r1c  : Pseudo<(outs GR8:$dst), (ins GR8:$src),
        "ror\t $dst",
      [(set GR8:$dst, (AVRrrc GR8:$src))]>;
}
// calls
def : Pat<(AVRcall (i16 tglobaladdr:$dst)),
          (CALL tglobaladdr:$dst)>;
def : Pat<(AVRcall (i16 texternalsym:$dst)),
          (CALL texternalsym:$dst)>;


def LO16 : SDNodeXForm<imm, [{
  return CurDAG->getTargetConstant((unsigned char)N->getZExtValue());
}]>;

def HI16 : SDNodeXForm<imm, [{
  return CurDAG->getTargetConstant((unsigned char)(N->getZExtValue() >> 8));
}]>;

