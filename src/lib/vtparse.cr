@[Link(ldflags: "-L#{__DIR__}/../../../vtparse/vtparse -lvtparse")]
lib VTParse
  enum State
    CSI_ENTRY = 1
    CSI_IGNORE = 2
    CSI_INTERMEDIATE = 3
    CSI_PARAM = 4
    DCS_ENTRY = 5
    DCS_IGNORE = 6
    DCS_INTERMEDIATE = 7
    DCS_PARAM = 8
    DCS_PASSTHROUGH = 9
    ESCAPE = 10
    ESCAPE_INTERMEDIATE = 11
    GROUND = 12
    OSC_STRING = 13
    SOS_PM_APC_STRING = 14
  end

  enum Action
    CLEAR = 1
    COLLECT = 2
    CSI_DISPATCH = 3
    ESC_DISPATCH = 4
    EXECUTE = 5
    HOOK = 6
    IGNORE = 7
    OSC_END = 8
    OSC_PUT = 9
    OSC_START = 10
    PARAM = 11
    PRINT = 12
    PUT = 13
    UNHOOK = 14
    ERROR = 15
  end

  alias ParserCb = (Parser*, VTParse::Action, LibC::UInt -> Void)

  struct Parser
    state : State
    cb : ParserCb
    intermediate_chars : StaticArray(UInt8, 3)
    num_intermediate_chars : LibC::Int
    ignore_flagged : LibC::Char
    params : StaticArray(LibC::Int, 16)
    num_params : LibC::Int
    user_data : Void*
    character_bytes : LibC::Int
    utf8_char : LibC::UInt
  end

  fun init = vtparse_init(parser : Parser*, cb : ParserCb) : Void
  fun parse = vtparse(parser : Parser*, str : LibC::Char*, len : LibC::UInt) : Void
end
