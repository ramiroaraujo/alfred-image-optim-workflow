# frozen_string_literal: true

require 'rspec'
require 'progress'
require 'tempfile'
require 'shellwords'
require 'csv'

describe Progress do
  before do
    Progress.stay_on_line = true
    Progress.highlight = true
    Progress.terminal_title = true

    allow(Progress).to receive(:start_beeper)
    allow(Progress).to receive(:time_to_print?).and_return(true)

    eta = instance_double(Progress::Eta, left: nil, elapsed: '0s')
    allow(Progress).to receive(:eta).and_return(eta)
  end

  describe 'integrity' do
    before do
      io = double(:<< => nil, :tty? => true)
      allow(Progress).to receive(:io).and_return(io)
    end

    it 'returns result from start block' do
      expect(Progress.start('Test') do
        'test'
      end).to eq('test')
    end

    it 'returns result from step block' do
      Progress.start 1 do
        expect(Progress.step{ 'test' }).to eq('test')
      end
    end

    it 'returns result from set block' do
      Progress.start 1 do
        expect(Progress.set(1){ 'test' }).to eq('test')
      end
    end

    it 'returns result from nested block' do
      expect([1, 2, 3].with_progress.map do |a|
        [1, 2, 3].with_progress.map do |b|
          a * b
        end
      end).to eq([[1, 2, 3], [2, 4, 6], [3, 6, 9]])
    end

    it 'checks respond_to? methods of self and of Enumerable' do
      with_progress = [1, 2, 3].with_progress

      (%w[each with_progress] + Enumerable.instance_methods).each do |method|
        expect(with_progress).to respond_to(method.to_sym)
      end
    end

    it 'returns false for respond_to? with non existing methods' do
      with_progress = [1, 2, 3].with_progress

      expect(with_progress).not_to respond_to(:should_not_be_defined)
    end

    it 'does not raise errors on extra step or stop' do
      expect do
        3.times_with_progress do
          Progress.start 'simple' do
            Progress.step
            Progress.step
            Progress.step
          end
          Progress.step
          Progress.stop
        end
        Progress.step
        Progress.stop
      end.not_to raise_error
    end

    describe Enumerable do
      let(:enum){ 0...1000 }

      describe 'with_progress' do
        it 'returns with block same as when called with each' do
          expect(enum.with_progress{}).to eq(enum.with_progress.each{})
        end

        it 'does not break each' do
          reference = enum.each
          enum.with_progress.each do |n|
            expect(n).to eq(reference.next)
          end
          expect{ reference.next }.to raise_error(StopIteration)
        end

        it 'does not break each_with_index' do
          reference = enum.each
          counter = 0
          enum.with_progress.each_with_index do |n, i|
            expect(n).to eq(reference.next)
            expect(i).to eq(counter)
            counter += 1
          end
          expect{ reference.next }.to raise_error(StopIteration)
        end

        it 'does not break find' do
          default = proc{ 'default' }
          expect(enum.with_progress.find{ |n| n == 100 }).
            to eq(enum.find{ |n| n == 100 })
          expect(enum.with_progress.find{ |n| n == 10_000 }).
            to eq(enum.find{ |n| n == 10_000 })
          expect(enum.with_progress.find(default){ |n| n == 10_000 }).
            to eq(enum.find(default){ |n| n == 10_000 })
        end

        it 'does not break map' do
          expect(enum.with_progress.map{ |n| n**2 }).to eq(enum.map{ |n| n**2 })
        end

        it 'does not break grep' do
          expect(enum.with_progress.grep(100)).to eq(enum.grep(100))
        end

        it 'does not break each_cons' do
          reference = enum.each_cons(3)
          enum.with_progress.each_cons(3) do |values|
            expect(values).to eq(reference.next)
          end
          expect{ reference.next }.to raise_error(StopIteration)
        end

        describe 'with_progress.with_progress' do
          it 'does not change existing instance' do
            wp = enum.with_progress('hello')
            expect{ wp.with_progress('world') }.not_to change(wp, :title)
          end

          it 'returns new instance with different title' do
            wp = enum.with_progress('hello')
            wp_wp = wp.with_progress('world')
            expect(wp.title).to eq('hello')
            expect(wp_wp.title).to eq('world')
            expect(wp_wp).not_to eq(wp)
            expect(wp_wp.enumerable).to eq(wp.enumerable)
          end
        end

        shared_examples 'yielding' do |enum|
          let(:expected){ [] }
          let(:got){ [] }

          after{ expect(got).to eq(expected) }

          it 'yields same objects with one block argument' do
            enum.each{ |a| expected << a }
            enum.with_progress{ |a| got << a }
          end

          it 'yields same objects with two block arguments' do
            enum.each{ |a, b| expected << [a, b] }
            enum.with_progress{ |a, b| got << [a, b] }
          end

          it 'yields same objects with splat block arguments' do
            enum.each{ |*a| expected << a }
            enum.with_progress{ |*a| got << a }
          end
        end

        [
          [1, [2, :b], [3, :c, :d, :e]],
          {1 => 1, 2 => 2, 3 => 3},
          [1, 2, 3].to_set,
        ].each do |enum|
          describe enum.class do
            it 'calls each only once' do
              expect(enum).to receive(:each).once.and_call_original
              expect(enum.with_progress.each{}).to eq(enum)
            end

            include_examples 'yielding', enum
          end
        end

        [
          100.times,
          'a'..'z',
        ].each do |enum|
          describe enum.class do
            it 'calls each twice' do
              enum_each = enum.each{}
              expect(enum).to receive(:each).at_most(:twice).and_call_original
              expect(enum.with_progress.each{}).to eq(enum_each)
            end

            include_examples 'yielding', enum
          end
        end

        describe String do
          it 'calls each only once on StringIO' do
            enum = "a\nb\nc".dup
            expect(enum).not_to receive(:each)
            io = StringIO.new(enum)
            expect(StringIO).to receive(:new).with(enum).and_return(io)
            expect(io).to receive(:each).once.and_call_original

            with_progress = Progress::WithProgress.new(enum)
            expect(with_progress).not_to receive(:warn)
            expect(with_progress.each{}).to eq(enum)
          end

          it 'yields same lines' do
            enum = "a\nb\nc"
            lines = []
            Progress::WithProgress.new(enum).each{ |line| lines << line }
            expect(lines).to eq(enum.lines.to_a)
          end
        end

        describe IO do
          [
            File.open(__FILE__),
            StringIO.new(File.read(__FILE__)),
          ].each do |enum|
            it "calls each only once for #{enum.class}" do
              expect(enum).to receive(:each).once.and_call_original

              with_progress = enum.with_progress
              expect(with_progress).not_to receive(:warn)
              expect(with_progress.each{}).to eq(enum)
            end
          end

          it 'calls each only once for Tempfile' do
            enum = Tempfile.open('progress')
            enum_each = enum.each{} # returns underlying File
            expect(enum_each).to receive(:each).once.and_call_original

            with_progress = enum.with_progress
            expect(with_progress).not_to receive(:warn)
            expect(with_progress.each{}).to eq(enum_each)
          end

          it 'calls each only once for IO and shows warning' do
            enum = IO.popen("cat #{__FILE__.shellescape}")
            expect(enum).to receive(:each).once.and_call_original

            with_progress = enum.with_progress
            expect(with_progress).to receive(:warn)
            expect(with_progress.each{}).to eq(enum)
          end

          [
            File.open(__FILE__),
            StringIO.new(File.read(__FILE__)),
            Tempfile.open('progress').tap do |f|
              f.write(File.read(__FILE__))
              f.rewind
            end,
            IO.popen("cat #{__FILE__.shellescape}"),
          ].each do |enum|
            it "yields same lines for #{enum.class}" do
              expect(enum.with_progress.entries).to eq(File.readlines(__FILE__))
            end
          end
        end

        describe CSV do
          if CSV.method_defined?(:pos)
            it 'calls each only once for CSV' do
              enum = CSV.open('spec/test.csv')
              expect(enum).to receive(:each).once.and_call_original

              with_progress = enum.with_progress
              expect(with_progress).not_to receive(:warn)
              expect(with_progress.each{}).
                to eq(CSV.open('spec/test.csv').each{})
            end
          else
            it 'calls each only once for CSV and shows warning' do
              enum = CSV.open('spec/test.csv', 'r')
              expect(enum).to receive(:each).once.and_call_original

              with_progress = enum.with_progress
              expect(with_progress).to receive(:warn)
              expect(with_progress.each{}).to eq(enum)
            end
          end

          it 'yields same lines for CSV' do
            csv = proc{ CSV.open('spec/test.csv', 'r') }
            expect(csv[].with_progress.entries).to eq(csv[].entries)
          end
        end
      end
    end

    describe Integer do
      let(:count){ 108 }

      it 'does not break times_with_progress' do
        reference = count.times
        count.times_with_progress do |i|
          expect(i).to eq(reference.next)
        end
        expect{ reference.next }.to raise_error(StopIteration)
      end

      it 'does not break times.with_progress' do
        reference = count.times
        count.times.with_progress do |i|
          expect(i).to eq(reference.next)
        end
        expect{ reference.next }.to raise_error(StopIteration)
      end
    end
  end

  describe 'output' do
    def stub_progress_io(io)
      allow(io).to receive(:tty?).and_return(true)
      allow(Progress).to receive(:io).and_return(io)
    end

    describe 'validity' do
      def run_example_progress
        Progress.start 5, 'Test' do
          Progress.step 2, 'simle'

          Progress.step 2, 'times' do
            3.times.with_progress{}
          end

          Progress.step 'enum' do
            3.times.to_a.with_progress{}
          end
        end
      end

      def title(str)
        "\e]0;#{str}\a"
      end

      def hl(str)
        "\e[1m#{str}\e[0m"
      end

      def unhl(str)
        str.gsub(/\e\[\dm/, '')
      end

      def on_line(str)
        "\r" + str + "\e[K"
      end

      def line(str)
        str + "\n"
      end

      def on_line_n_title(str)
        [on_line(str), title(unhl(str))]
      end

      def line_n_title(str)
        [line(str), title(unhl(str))]
      end

      it 'produces valid output when staying on line' do
        Progress.stay_on_line = true

        stub_progress_io(io = StringIO.new)
        run_example_progress

        expect(io.string).to eq([
          on_line_n_title("Test: #{hl '......'}"),
          on_line_n_title("Test: #{hl ' 40.0%'} - simle"),
          on_line_n_title("Test: #{hl ' 40.0%'} > #{hl '......'}"),
          on_line_n_title("Test: #{hl ' 53.3%'} > #{hl ' 33.3%'}"),
          on_line_n_title("Test: #{hl ' 66.7%'} > #{hl ' 66.7%'}"),
          on_line_n_title("Test: #{hl ' 80.0%'} > 100.0%"),
          on_line_n_title("Test: #{hl ' 80.0%'} - times"),
          on_line_n_title("Test: #{hl ' 80.0%'} > #{hl '......'}"),
          on_line_n_title("Test: #{hl ' 86.7%'} > #{hl ' 33.3%'}"),
          on_line_n_title("Test: #{hl ' 93.3%'} > #{hl ' 66.7%'}"),
          on_line_n_title('Test: 100.0% > 100.0%'),
          on_line_n_title('Test: 100.0% - enum'),
          on_line('Test: 100.0% (elapsed: 0s) - enum') + "\n",
          title(''),
        ].flatten.join)
      end

      it 'produces valid output when not staying on line' do
        Progress.stay_on_line = false

        stub_progress_io(io = StringIO.new)
        run_example_progress

        expect(io.string).to eq([
          line_n_title("Test: #{hl '......'}"),
          line_n_title("Test: #{hl ' 40.0%'} - simle"),
          line_n_title("Test: #{hl ' 40.0%'} > #{hl '......'}"),
          line_n_title("Test: #{hl ' 53.3%'} > #{hl ' 33.3%'}"),
          line_n_title("Test: #{hl ' 66.7%'} > #{hl ' 66.7%'}"),
          line_n_title("Test: #{hl ' 80.0%'} > 100.0%"),
          line_n_title("Test: #{hl ' 80.0%'} - times"),
          line_n_title("Test: #{hl ' 80.0%'} > #{hl '......'}"),
          line_n_title("Test: #{hl ' 86.7%'} > #{hl ' 33.3%'}"),
          line_n_title("Test: #{hl ' 93.3%'} > #{hl ' 66.7%'}"),
          line_n_title('Test: 100.0% > 100.0%'),
          line_n_title('Test: 100.0% - enum'),
          line('Test: 100.0% (elapsed: 0s) - enum'),
          title(''),
        ].flatten.join)
      end
    end

    describe 'different call styles' do
      let(:count_a){ 13 }
      let(:count_b){ 17 }
      let(:reference_output) do
        stub_progress_io(reference_io = StringIO.new)
        count_a.times.with_progress('Test') do
          count_b.times.with_progress{}
        end
        reference_io.string
      end
      let(:io){ StringIO.new }

      before do
        stub_progress_io(io)
      end

      it 'outputs same when called without block' do
        Progress(count_a, 'Test')
        count_a.times do
          Progress.step do
            Progress.start(count_b)
            count_b.times do
              Progress.step
            end
            Progress.stop
          end
        end
        Progress.stop
        expect(io.string).to eq(reference_output)
      end

      it 'outputs same when called with block' do
        Progress(count_a, 'Test') do
          count_a.times do
            Progress.step do
              Progress.start(count_b) do
                count_b.times do
                  Progress.step
                end
              end
            end
          end
        end
        expect(io.string).to eq(reference_output)
      end

      it 'outputs same when called using with_progress on list' do
        count_a.times.to_a.with_progress('Test') do
          count_b.times.to_a.with_progress{}
        end
        expect(io.string).to eq(reference_output)
      end
    end

    describe '.io' do
      it 'is $stderr by default' do
        expect(Progress.io).to be $stderr
      end

      it 'is settable' do
        io = StringIO.new

        Progress.io = io

        expect(Progress.io).to be io

        Progress.io = nil
      end

      it 'is resettable' do
        Progress.io = :something

        expect(Progress.io).not_to be $stderr

        Progress.io = nil

        expect(Progress.io).to be $stderr
      end
    end

    describe '.io_tty?' do
      subject{ Progress.io_tty? }

      let(:tty?){ false }
      let(:progress_tty){ nil }

      before do
        allow(Progress.io).to receive(:tty?).and_return(tty?)
        allow(ENV).to receive(:[]).with('PROGRESS_TTY').and_return(progress_tty)
      end

      it{ is_expected.not_to be_truthy }

      context 'when io is tty' do
        let(:tty?){ true }

        it{ is_expected.to be_truthy }
      end

      context 'when PROGRESS_TTY' do
        let(:tty?){ true }

        it{ is_expected.to be_truthy }
      end
    end

    describe '.without_beeper' do
      before do
        allow(Progress).to receive(:start_beeper).and_call_original
        allow(Progress::Beeper).to receive(:new) do |*, &block|
          @block = block
          double(restart: nil, stop: nil)
        end
        expect(Progress).to receive(:print_message).exactly(print_times).times
      end

      context 'when not used' do
        let(:print_times){ 3 }

        it 'allows beeper to print progress' do
          Progress.start do
            @block.call
          end
        end
      end

      context 'when used around progress block' do
        let(:print_times){ 2 }

        it 'stops beeper from printing progress' do
          Progress.without_beeper do
            Progress.start do
              @block.call
            end
          end
        end
      end

      context 'when used inside progress block' do
        let(:print_times){ 2 }

        it 'stops beeper from printing progress' do
          Progress.start do
            Progress.without_beeper do
              @block.call
            end
          end
        end
      end
    end
  end
end
