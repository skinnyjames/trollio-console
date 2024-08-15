lib LibC 
  {% begin %}
    {% if flag?(:darwin) || flag?(:bsd) %}
      TIOCGWINSZ = 1074295912
      TIOCSWINSZ = 2148037735
    {% elsif flag?(:unix) %}
      TIOCGWINSZ = 0x5413
      TIOCSWINSZ = 0x5414
    {% else %} # Solaris
      TIOCGWINSZ = 0x5468
      TIOCSWINSZ = 111
    {% end %}
  {% end %}

  fun dup(fd : LibC::Int) : LibC::Int
    
  struct WinSize
    ws_row : LibC::UShort
    ws_col : LibC::UShort
    ws_xpixel : LibC::UInt
    ws_ypixel : LibC::UInt
  end

  @[Flags]
  enum OpenFlags
    ReadWrite
    NoCtty
  end

  fun set_sid = setsid : Int32
  fun posix_openpt(flags : LibC::Int) : LibC::Int
  fun forkpty(amaster : LibC::Int*, name : LibC::Char*, termp : LibC::Termios*, winp : WinSize*) : LibC::Int
  fun grantpt(fd : LibC::Int) : LibC::Int
  fun unlockpt(fd : LibC::Int) : LibC::Int
  fun ptsname(fd : LibC::Int) : LibC::Char*
  fun ioctl(fd : Int, request : ULong, ...) : Int
end

class Trollio::Console::Pty
  def self.termios
    termios = uninitialized LibC::Termios
    termios.c_iflag = LibC::BRKINT | LibC::INLCR
    termios.c_oflag = LibC::OPOST | LibC::ONLCR | LibC::ONOCR | LibC::ONLRET
    termios.c_cflag = LibC::CREAD  | LibC::HUPCL
    termios.c_lflag = LibC::ISIG | LibC::IEXTEN | LibC::ECHO | LibC::ECHOE | LibC::ECHOK | LibC::ICANON
    termios.c_cc[3] = 0x04
    termios
  end

  def self.winsize(row = 20, col = 20)
    LibC::WinSize.new(ws_row: row, ws_col: col, ws_xpixel: 0, ws_ypixel: 0)
  end

  def self.fork(command, env)
    {% if flag?(:preview_mt) %}
      raise "cant do that"
    {% end %}

    original_line_discipline = uninitialized LibC::Termios
    LibC.tcgetattr(STDIN.fd, pointerof(original_line_discipline))

    line_discipline = termios
    # window_size = winsize(rows, columns)
    name = uninitialized Pointer(UInt8)
    pid = LibC.forkpty(out fd, Pointer(UInt8).null, pointerof(line_discipline), Pointer(LibC::WinSize).null)

    at_exit do
      LibC.tcsetattr(STDIN.fd, LibC::TCSANOW, pointerof(original_line_discipline))
    end

    if pid.zero?
      Process.exec(
        command,
        shell: false,
        env: env
      )
    
      LibC.set_sid
      exit(0)
    end

    io = ::IO::FileDescriptor.from_stdio(fd)
    # io.raw!
    new(io)
  end

  getter io : ::IO::FileDescriptor

  def initialize(@io : ::IO::FileDescriptor); end

  def size
    winsize = uninitialized LibC::WinSize
    ret = LibC.ioctl(@fd, LibC::TIOCGWINSZ, pointerof(winsize))
    raise "bad size" if ret < 0

    winsize
  end

  def set_size(row, col, width, height)
    win = LibC::WinSize.new(ws_row: row, ws_col: col, ws_xpixel: 0, ws_ypixel: 0)

    ret = LibC.ioctl(io.fd, LibC::TIOCSWINSZ, pointerof(win))
    if ret < 0
      puts Errno.value.message
    end
  end
end