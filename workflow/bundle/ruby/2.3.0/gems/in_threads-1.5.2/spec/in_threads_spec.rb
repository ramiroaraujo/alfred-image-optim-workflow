# frozen_string_literal: true

require 'rspec'
require 'rspec/retry'
require 'in_threads'

RSpec.configure do |config|
  config.order = :random

  config.verbose_retry = true

  config.around :each, :flaky do |ex|
    ex.run_with_retry :retry => 3
  end
end

# check if break causes LocalJumpError
# not in jruby in mri < 1.9
# https://github.com/jruby/jruby/issues/4697
SKIP_IF_BREAK_IN_THREAD_IS_IGNORED = begin
  Thread.new{ break }.join
  'can not handle break in thread'
rescue LocalJumpError
  false
end

def describe_enum_method(method, &block)
  if Enumerable.method_defined?(method) || method.to_s == 'each'
    describe "##{method}", &block
  else
    describe "##{method}" do
      let(:enum){ 10.times }

      it 'is not defined' do
        expect{ enum.in_threads.send(method) }.
          to raise_error(NoMethodError){ |error| expect(error.name.to_s).to eq(method.to_s) }
      end
    end
  end
end

class TestObject
  SLEEP_TIME = 0.002

  def initialize(value)
    @value = value
  end

  def fetch
    @value
  end

  def compute
    wait; @value
  end

private

  def wait
    sleep SLEEP_TIME
  end
end

describe InThreads do
  let!(:mutex){ Mutex.new }

  # Check if all threads are joined
  let!(:threads_before){ Thread.list }
  after do
    threads = (Thread.list - threads_before).reject do |thread|
      thread.respond_to?(:backtrace) && thread.backtrace.none?{ |l| l =~ /in_threads/ }
    end
    expect(threads).to eq([]), 'expected all created threads to be joined'
  end

  describe 'initialization' do
    it 'complains about using with non enumerable' do
      expect{ InThreads.new(1) }.to raise_error(ArgumentError)
    end

    [1..10, 10.times, {}, []].each do |o|
      it "does not complain about using with #{o.class}" do
        expect{ InThreads.new(o) }.not_to raise_error
      end
    end

    it 'complains about using less than 2 threads' do
      expect{ InThreads.new(10.times, 1) }.to raise_error(ArgumentError)
    end

    it 'does not complain about using 2 or more threads' do
      expect{ InThreads.new(10.times, 2) }.not_to raise_error
    end
  end

  describe '#in_threads' do
    context 'when applied to an instance of InThreads' do
      let(:threaded){ 10.times.in_threads(10) }
      let(:double_threaded){ threaded.in_threads(20) }

      it 'creates new instance' do
        expect(double_threaded.class).to eq(threaded.class)
        expect(double_threaded.object_id).not_to eq(threaded.object_id)
      end

      it 'changes the maximum thread count' do
        expect(threaded.thread_count).to eq(10)
        expect(double_threaded.thread_count).to eq(20)
      end

      it 'preserves the enumerable' do
        expect(threaded.enumerable).to be(double_threaded.enumerable)
      end
    end
  end

  describe 'consistency' do
    let(:enum){ 100.times }

    describe 'runs in specified number of threads' do
      let(:enum){ 40.times }
      let(:threads){ 4 }

      %w[each map all?].each do |method|
        it "for ##{method}", :flaky do
          thread_count = 0
          max_thread_count = 0
          enum.in_threads(threads).send(method) do
            mutex.synchronize do
              thread_count += 1
              max_thread_count = [max_thread_count, thread_count].max
            end
            sleep TestObject::SLEEP_TIME
            mutex.synchronize do
              thread_count -= 1
            end
          end
          expect(thread_count).to eq(0)
          expect(max_thread_count).to eq(threads)
        end
      end
    end

    describe 'exception/break handling' do
      %w[each map all?].each do |method|
        describe "for ##{method}" do
          it 'passes exception raised in block' do
            expect{ enum.in_threads.send(method){ fail 'expected' } }.to raise_error('expected')
          end

          it 'passes exception raised during iteration' do
            def enum.each
              fail 'expected'
            end

            expect{ enum.in_threads.send(method){} }.to raise_error('expected')
          end

          it 'handles break', :skip => SKIP_IF_BREAK_IN_THREAD_IS_IGNORED do
            expect(enum).not_to receive(:unexpected)
            def enum.each(&block)
              20.times(&block)
              unexpected
            end

            value = double
            expect(enum.in_threads(10).send(method) do
              break value
            end).to eq(value)
          end

          it 'stops iterating after exception' do
            expect(enum).not_to receive(:unexpected)
            def enum.each(&block)
              20.times(&block)
              unexpected
            end

            expect do
              enum.in_threads(10).send(method) do |i|
                fail 'expected' if i == 5

                sleep TestObject::SLEEP_TIME
              end
            end.to raise_error('expected')
          end

          it 'finishes blocks started before exception' do
            started = []
            finished = []

            expect do
              enum.in_threads(10).send(method) do |i|
                fail 'expected' if i == 5

                mutex.synchronize{ started << i }
                sleep TestObject::SLEEP_TIME
                mutex.synchronize{ finished << i }
              end
            end.to raise_error('expected')

            expect(finished).to match_array(started)
          end

          context 'exception order' do
            before do
              stub_const('Order', Queue.new)
            end

            it 'passes exception raised during iteration if it happens earlier than in block' do
              def enum.each(&block)
                5.times(&block)
                begin
                  fail 'expected'
                ensure
                  Order.push nil
                end
              end

              expect do
                enum.in_threads(10).send(method) do
                  Thread.pass while Order.empty?
                  sleep TestObject::SLEEP_TIME
                  fail 'unexpected'
                end
              end.to raise_error('expected')
            end

            it 'passes exception raised in block if it happens earlier than during iteration' do
              def enum.each(&block)
                5.times(&block)
                Thread.pass while Order.empty?
                sleep TestObject::SLEEP_TIME
                fail 'unexpected'
              end

              expect do
                enum.in_threads(10).send(method) do
                  begin
                    fail 'expected'
                  ensure
                    Order.push nil
                  end
                end
              end.to raise_error('expected')
            end

            it 'passes first exception raised in block' do
              expect do
                enum.in_threads(10).send(method) do |i|
                  if i == 5
                    begin
                      fail 'expected'
                    ensure
                      Order.push nil
                    end
                  else
                    Thread.pass while Order.empty?
                    sleep TestObject::SLEEP_TIME
                    fail 'unexpected'
                  end
                end
              end.to raise_error('expected')
            end
          end
        end
      end
    end

    it 'does not yield all elements when not needed' do
      expect(enum).not_to receive(:unexpected)

      def enum.each(&block)
        100.times(&block)
        unexpected
      end

      enum.in_threads(10).all?{ false }
    end

    describe 'calls underlying enumerable #each only once' do
      %w[each map all?].each do |method|
        it "for ##{method}" do
          expect(enum).to receive(:each).once.and_call_original
          enum.in_threads.send(method){ sleep TestObject::SLEEP_TIME }
        end
      end
    end

    describe 'block arguments' do
      %w[each map all? each_entry each_with_index].each do |method|
        describe_enum_method method do
          it 'passes arguments as for not threaded call' do
            enum = Class.new do
              include Enumerable

              def each
                yield
                yield 1
                yield 2, 3
                yield 4, 5, 6
              end
            end.new

            expected = []
            enum.send(method) do |a, b, c|
              expected << [a, b, c]
            end

            yielded = []
            enum.in_threads.send(method) do |a, b, c|
              mutex.synchronize{ yielded << [a, b, c] }
            end

            expect(yielded).to match_array(expected)
          end
        end
      end
    end
  end

  describe 'methods' do
    define :be_faster_than do
      coef = 0.666 # small coefficient, should be more if sleep time is bigger

      def measure
        start = Time.now
        yield
        Time.now - start
      end

      match do |actual|
        measure(&actual) < measure(&block_arg) * coef
      end

      failure_message{ "expected to be faster (coef. #{coef})" }

      supports_block_expectations
    end

    it 'lists all incompatible methods' do
      expect(InThreads::INCOMPATIBLE_METHODS.sort_by(&:to_s)).
        to include(*(
          Enumerable.instance_methods.map(&:to_sym) -
          InThreads.public_instance_methods(false).map(&:to_sym)
        ).sort_by(&:to_s))
    end

    context 'threaded' do
      let(:item_count){ 40 }
      let(:value_proc){ proc{ rand } }
      let(:items){ Array.new(item_count){ |i| TestObject.new(value_proc[i]) } }
      let(:enum){ items }

      describe_enum_method :each do
        it 'returns same enum after running' do
          expect(enum.in_threads.each(&:compute)).to eq(enum)
        end

        it 'executes block for each element' do
          yielded = []
          enum.in_threads.each do |item|
            mutex.synchronize{ yielded << item }
          end
          expect(yielded).to match_array(items)
        end

        it 'runs faster with threads', :flaky do
          expect{ enum.in_threads.each(&:compute) }.
            to be_faster_than{ enum.each(&:compute) }
        end

        it 'runs faster with more threads', :flaky do
          expect{ enum.in_threads(10).each(&:compute) }.
            to be_faster_than{ enum.in_threads(2).each(&:compute) }
        end

        it 'returns same enum without block' do
          expect(enum.in_threads.each.to_a).to eq(enum.each.to_a)
        end
      end

      %w[each_with_index enum_with_index].each do |method|
        describe_enum_method method do
          let(:block){ proc{ |o, _i| o.compute } }

          it 'returns same result with threads' do
            expect(enum.in_threads.send(method, &block)).
              to eq(enum.send(method, &block))
          end

          it 'yields same objects' do
            yielded = []
            enum.in_threads.send(method) do |o, i|
              mutex.synchronize{ yielded << [o, i] }
            end
            expect(yielded).to match_array(enum.send(method))
          end

          it 'runs faster with threads', :flaky do
            expect{ enum.in_threads.send(method, &block) }.
              to be_faster_than{ enum.send(method, &block) }
          end

          it 'returns same enum without block' do
            expect(enum.in_threads.send(method).to_a).
              to eq(enum.send(method).to_a)
          end
        end
      end

      describe_enum_method :reverse_each do
        let(:item_count){ 100 }

        it 'returns same result with threads' do
          expect(enum.in_threads.reverse_each(&:compute)).
            to eq(enum.reverse_each(&:compute))
        end

        it 'yields same objects in reverse order' do
          yielded = []
          enum.in_threads.reverse_each do |o|
            mutex.synchronize{ yielded << o }
          end

          expect(yielded).to match_array(items)
          expect(yielded.index(items.last)).
            to be < yielded.index(items[items.length / 4])
          expect(yielded.index(items.first)).
            to be > yielded.index(items[-items.length / 4])
        end

        it 'runs faster with threads', :flaky do
          expect{ enum.in_threads.reverse_each(&:compute) }.
            to be_faster_than{ enum.reverse_each(&:compute) }
        end

        it 'returns same enum without block' do
          expect(enum.in_threads.reverse_each.to_a).
            to eq(enum.reverse_each.to_a)
        end
      end

      %w[
        all? any? none? one?
        detect find find_index drop_while take_while
      ].each do |method|
        describe_enum_method method do
          let(:value_proc){ proc{ |i| i.odd? } }

          it 'returns same result with threads' do
            expect(enum.in_threads.send(method, &:compute)).
              to eq(enum.send(method, &:compute))
          end

          it 'yields same objects but not all' do
            expected = []
            enum.send(method) do |o|
              expected << o
              o.compute
            end

            yielded = []
            enum.in_threads.send(method) do |o|
              mutex.synchronize{ yielded << o }
              o.compute
            end

            expect(yielded.length).to be >= expected.length
            expect(yielded.length).to be <= items.length * 0.5
          end

          context 'speed' do
            let(:value_proc) do
              proc{ %w[all? drop_while take_while].include?(method) }
            end

            it 'runs faster with threads', :flaky do
              expect{ enum.in_threads.send(method, &:compute) }.
                to be_faster_than{ enum.send(method, &:compute) }
            end
          end
        end
      end

      %w[partition find_all select reject count].each do |method|
        describe_enum_method method do
          let(:value_proc){ proc{ rand < 0.5 } }

          it 'returns same result with threads' do
            expect(enum.in_threads.send(method, &:compute)).
              to eq(enum.send(method, &:compute))
          end

          it 'yields same objects' do
            yielded = []
            enum.in_threads.send(method) do |o|
              mutex.synchronize{ yielded << o }
            end
            expect(yielded).to match_array(items)
          end

          it 'runs faster with threads', :flaky do
            expect{ enum.in_threads.send(method, &:compute) }.
              to be_faster_than{ enum.send(method, &:compute) }
          end
        end
      end

      %w[
        collect map
        group_by max_by min_by minmax_by sort_by
        sum uniq
      ].each do |method|
        describe_enum_method method do
          it 'returns same result with threads' do
            expect(enum.in_threads.send(method, &:compute)).
              to eq(enum.send(method, &:compute))
          end

          it 'yields same objects' do
            yielded = []
            enum.in_threads.send(method) do |o|
              mutex.synchronize{ yielded << o }
              o.compute
            end
            expect(yielded).to match_array(items)
          end

          it 'runs faster with threads', :flaky do
            expect{ enum.in_threads.send(method, &:compute) }.
              to be_faster_than{ enum.send(method, &:compute) }
          end
        end
      end

      %w[each_cons each_slice enum_slice enum_cons].each do |method|
        describe_enum_method method do
          let(:block){ proc{ |a| a.each(&:compute) } }

          it 'yields same objects' do
            yielded = []
            enum.in_threads.send(method, 3) do |a|
              mutex.synchronize{ yielded << a }
            end
            expect(yielded).to match_array(items.send(method, 3))
          end

          it 'returns same with block' do
            expect(enum.in_threads.send(method, 3, &block)).
              to eq(enum.send(method, 3, &block))
          end

          it 'runs faster with threads', :flaky do
            expect{ enum.in_threads.send(method, 3, &block) }.
              to be_faster_than{ enum.send(method, 3, &block) }
          end

          it 'returns same without block' do
            expect(enum.in_threads.send(method, 3).to_a).
              to eq(enum.send(method, 3).to_a)
          end
        end
      end

      describe_enum_method :zip do
        let(:block){ proc{ |a| a.each(&:compute) } }

        it 'yields same objects' do
          yielded = []
          enum.in_threads.zip(enum, enum) do |a|
            mutex.synchronize{ yielded << a }
          end
          expect(yielded).to match_array(enum.zip(enum, enum))
        end

        it 'returns same with block' do
          expect(enum.in_threads.zip(enum, enum, &block)).
            to eq(enum.zip(enum, enum, &block))
        end

        it 'runs faster with threads', :flaky do
          expect{ enum.in_threads.zip(enum, enum, &block) }.
            to be_faster_than{ enum.zip(enum, enum, &block) }
        end

        it 'returns same without block' do
          expect(enum.in_threads.zip(enum, enum)).
            to eq(enum.zip(enum, enum))
        end
      end

      describe_enum_method :cycle do
        it 'yields same objects' do
          yielded = []
          enum.in_threads.cycle(3) do |o|
            mutex.synchronize{ yielded << o }
          end
          expect(yielded).to match_array(enum.cycle(3))
        end

        it 'runs faster with threads', :flaky do
          expect{ enum.in_threads.cycle(3, &:compute) }.
            to be_faster_than{ enum.cycle(3, &:compute) }
        end

        it 'returns same enum without block' do
          expect(enum.in_threads.cycle(3).to_a).
            to eq(enum.cycle(3).to_a)
        end
      end

      %w[grep grep_v].each do |method|
        describe_enum_method method do
          let(:value_proc){ proc{ rand < 0.5 } }

          let(:matcher) do
            double.tap do |matcher|
              def matcher.===(item)
                item.fetch
              end
            end
          end

          it 'yields same objects' do
            yielded = []
            enum.in_threads.send(method, matcher) do |item|
              mutex.synchronize{ yielded << item }
            end
            expect(yielded).to match_array(enum.send(method, matcher))
          end

          it 'returns same with block' do
            expect(enum.in_threads.send(method, matcher, &:compute)).
              to eq(enum.send(method, matcher, &:compute))
          end

          it 'runs faster with threads', :flaky do
            expect{ enum.in_threads.send(method, matcher, &:compute) }.
              to be_faster_than{ enum.send(method, matcher, &:compute) }
          end

          it 'returns same without block' do
            expect(enum.in_threads.send(method, matcher)).
              to eq(enum.send(method, matcher))
          end
        end
      end

      describe_enum_method :each_entry do
        before do
          def enum.each
            (count / 3).times do
              yield
              yield 1
              yield 2, 3
            end
          end
        end
        let(:block){ proc{ |o| TestObject.new(o).compute } }

        it 'returns same result with threads' do
          expect(enum.in_threads.each_entry(&block)).
            to eq(enum.each_entry(&block))
        end

        it 'executes block for each element' do
          expected = []
          enum.each_entry do |*o|
            expected << o
          end

          yielded = []
          enum.in_threads.each_entry do |*o|
            mutex.synchronize{ yielded << o }
          end

          expect(yielded).to match_array(expected)
        end

        it 'runs faster with threads', :flaky do
          expect{ enum.in_threads.each_entry(&block) }.
            to be_faster_than{ enum.each_entry(&block) }
        end

        it 'returns same enum without block' do
          expect(enum.in_threads.each_entry.to_a).
            to eq(enum.each_entry.to_a)
        end
      end

      %w[flat_map collect_concat].each do |method|
        describe_enum_method method do
          let(:items){ super().each_slice(3).to_a }
          let(:block){ proc{ |a| a.map(&:compute) } }

          it 'returns same result with threads' do
            expect(enum.in_threads.send(method, &block)).
              to eq(enum.send(method, &block))
          end

          it 'yields same objects' do
            yielded = []
            enum.in_threads.send(method) do |a|
              mutex.synchronize{ yielded << a }
            end
            expect(yielded).to match_array(items)
          end

          it 'runs faster with threads', :flaky do
            expect{ enum.in_threads.send(method, &block) }.
              to be_faster_than{ enum.send(method, &block) }
          end

          it 'returns same enum without block' do
            expect(enum.in_threads.send(method).to_a).
              to eq(enum.send(method).to_a)
          end
        end
      end
    end

    context 'unthreaded' do
      let(:enum){ (1..10).each }

      %w[inject reduce].each do |method|
        describe_enum_method method do
          it 'returns same result' do
            combiner = proc{ |memo, o| memo + o }
            expect(enum.in_threads.send(method, 0, &combiner)).
              to eq(enum.send(method, 0, &combiner))
          end
        end
      end

      %w[max min minmax sort].each do |method|
        describe_enum_method method do
          it 'returns same result' do
            comparer = proc{ |a, b| a <=> b }
            expect(enum.in_threads.send(method, &comparer)).
              to eq(enum.send(method, &comparer))
          end
        end
      end

      %w[to_a entries].each do |method|
        describe_enum_method method do
          it 'returns same result' do
            expect(enum.in_threads.send(method)).to eq(enum.send(method))
          end
        end
      end

      %w[drop take].each do |method|
        describe_enum_method method do
          it 'returns same result' do
            expect(enum.in_threads.send(method, 2)).to eq(enum.send(method, 2))
          end
        end
      end

      %w[first].each do |method|
        describe_enum_method method do
          it 'returns same result' do
            expect(enum.in_threads.send(method)).to eq(enum.send(method))
            expect(enum.in_threads.send(method, 3)).to eq(enum.send(method, 3))
          end
        end
      end

      %w[include? member?].each do |method|
        describe_enum_method method do
          it 'returns same result' do
            expect(enum.in_threads.send(method, enum.to_a[10])).to eq(enum.send(method, enum.to_a[10]))
          end
        end
      end

      describe_enum_method :each_with_object do
        let(:block){ proc{ |o, h| h[o] = true } }

        it 'returns same result' do
          expect(enum.in_threads.each_with_object({}, &block)).to eq(enum.each_with_object({}, &block))
        end
      end

      %w[chunk slice_before slice_after].each do |method|
        describe_enum_method method do
          it 'returns same result' do
            expect(enum.in_threads.send(method, &:odd?).to_a).to eq(enum.send(method, &:odd?).to_a)
          end
        end
      end
    end
  end
end
