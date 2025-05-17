class TinyVM
    def initialize(bytecode)
        @bytecode = bytecode
        @ip = 0 # インストラクションポインタ。もしくはプログラムカウンタとも。CPUが次に実行する命令のアドレスを指す。
        @stack = [] # スタックマシンのスタック。
        @memory = {}
    end

    def run
        loop do
            opcode = fetch
            raise "opcode is nil" if opcode.nil? # 利用者側にnilだよと通知してあげる
            case opcode
            when :push
                value = fetch
                @stack << value
            when :pop
                raise "Stack underflow" if @stack.size < 1
                @stack.pop
            when :dup
                raise "Stack underflow" if @stack.size < 1
                @stack << @stack.last
            when :swap
                raise "Stack underflow" if @stack.size < 2
                top = @stack.pop
                second = @stack.pop
                @stack << top
                @stack << second
            when :add
                binary_op { |a, b| a + b }
            when :sub
                binary_op { |a, b| a - b }
            when :mul
                binary_op { |a, b| a * b }
            when :div
                binary_op { |a, b| a / b }
            when :store
                name = fetch
                value = @stack.pop
                @memory[name] = value
            when :load
                name = fetch
                @stack << @memory[name]
            when :jmp
                addr = fetch
                @ip = addr
            when :jmp_if_zero
                addr = fetch
                @ip = addr if @stack.pop == 0
            when :print
                raise "Stack underflow" if @stack.size < 1
                puts @stack.pop
            when :halt
                break
            else
                raise "Unknown opcode: #{opcode}"
            end
        end
    end

    private

    def fetch
        # print @stack
        val = @bytecode[@ip]
        # print val
        @ip += 1
        val
    end

    private

    # mymemo: rubyのblockはその場で定義した処理を渡せる
    def binary_op(&block)
        raise "Stack underflow" if @stack.size < 2
        top = @stack.pop
        second = @stack.pop
        @stack << block.call(second, top)
    end

end

def compile_line(line)
    tokens = line.strip.split(/\s+/) # スペースなどで分割
    if tokens[1] == '=' && tokens[3] == '+'
        var = tokens[0].to_sym
        left = tokens[2].to_i
        right = tokens[4].to_i
        return [:push, left, :push, right, :add, :store, var]
    elsif tokens[0] == 'print'
        return [:load, tokens[1].to_sym, :print]
    else
        raise "Unknown line: #{line}"
    end
end

def compile(source)
    lines = source.lines.map(&:strip).reject{ |l| l.empty? || l.start_with?('#') }
    bytecode = lines.flat_map{ |line| compile_line(line) }
    bytecode << :halt
end

# program = [:push, 1, :push, 2, :add, :store, :x, :halt]
source = <<~SRC
    # コメント
    x = 1 + 2
    print x
SRC

program = compile(source)

print program # バイトコードを表示

vm = TinyVM.new(program)
vm.run