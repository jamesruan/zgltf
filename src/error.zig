const std = @import("std");

pub const ParseError = error{
    MissingField,
    NullField,
    InvalidType,
    NegativeValue,
    InvalidGlb,
    InvalidGlbMagic,
    UnsupportedGlbVersion,
    TruncatedGlb,
    TruncatedGlbChunk,
    MultipleJsonChunks,
    MultipleBinChunks,
    MissingJsonChunk,
};
