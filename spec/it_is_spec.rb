describe :ItIs do
  constants = %w(Base Foo Bar Baz)

  before(:each) do
    Base = Class.new
    Base.send(:extend, ActiveSupport::DescendantsTracker)
    Foo = Class.new(Base)
    Bar = Class.new(Base)
    Baz = Class.new(Bar)
  end

  after(:each) do
    constants.each {|const| Object.send(:remove_const, const)}
  end

  it 'binds to class' do
    klass = Class.new
    klass.class_eval do
      include(ItIs::DSL)

      it_will_be(:helper, Base)
    end

    expect(klass).to respond_to :it_is_helper_for

    descendant = Class.new(klass)
    descendant.it_is_helper_for('Foo')

    expect(klass).to respond_to :helper_for
    expect(klass.helper_for(Foo)).to eql descendant
  end

  describe 'simple examples with helpers' do
    let(:base_helper) do
      base = Class.new
      base.class_eval do
        include ItIs::DSL
        it_will_be(:helper, Base)
      end
      base
    end

    it 'works with inheritance' do
      foo_helper = Class.new(base_helper)
      bar_helper = Class.new(base_helper)

      base_helper.it_is_helper_for 'Base'
      foo_helper.it_is_helper_for 'Foo'
      bar_helper.it_is_helper_for 'Bar'

      expect(base_helper.helper_for(Base)).to eql base_helper
      expect(base_helper.helper_for(Foo)).to eql foo_helper
      expect(base_helper.helper_for(Bar)).to eql bar_helper
      expect(base_helper.helper_for(Baz)).to eql bar_helper
    end

    it 'detects cycles in relations' do
      pending
      foo_helper = Class.new(base_helper)

      base_helper.it_is_helper_for 'Foo'
      foo_helper.it_is_helper_for 'Base'

      expect {base_helper.helper_for(Foo)}.to raise_error
      expect {base_helper.helper_for(Base)}.to raise_error
    end

    it 'raises error on double mapping' do
      foo_helper = Class.new(base_helper)
      base_helper.it_is_helper_for 'Foo'
      foo_helper.it_is_helper_for 'Foo'

      expect {base_helper.helper_for(Foo)}.to raise_error
      expect {base_helper.helper_for(Base)}.to raise_error
    end
  end
end