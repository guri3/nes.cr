class Interrupts
  @nmi : Bool
  @irq : Bool

  def initialize
    @nmi = false
    @irq = false
  end

  def is_nmi_assert? : Bool
    @npm
  end

  def is_irq_assert? : Bool
    @irq
  end

  def assert_nmi
    @nmi = true
  end

  def deassert_nmi
    @nmi = false
  end

  def assert_irq
    @irq = true
  end

  def deassert_nmi
    @irq = false
  end
end
