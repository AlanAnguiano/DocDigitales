RSpec.describe Timbrado, type: :model do
  let(:factura) { Factura.create!(folio: "TEST-SPEC-01") }

  describe 'associations' do
    it { is_expected.to belong_to(:factura) }
  end

  describe 'validations' do
    subject do
      described_class.new(
        factura: factura,
        external_id: "req-abc-123",
        amount: 100.50,
        status: Timbrado::STATUS[:timbrada],
        uuid_fiscal: SecureRandom.uuid
      )
    end

    it { is_expected.to validate_presence_of(:external_id) }
    it { is_expected.to validate_uniqueness_of(:external_id) }
    it { is_expected.to validate_presence_of(:amount) }
    it { is_expected.to validate_numericality_of(:amount) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_inclusion_of(:status).in_array(Timbrado::STATUS.values) }

    it 'es valido cuando tiene uuid_fiscal' do
      expect(subject).to be_valid
    end

    it 'necesita uuid_fiscal si el status es timbrada' do
      subject.uuid_fiscal = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:uuid_fiscal]).to be_present
    end

    it "necesita 'error' si estatus es 'fallida'" do
      subject.status = Timbrado::STATUS[:fallida]
      subject.uuid_fiscal = nil
      subject.error = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:error]).to be_present
    end

    it 'es valida cuando falla con error' do
      subject.status = Timbrado::STATUS[:fallida]
      subject.uuid_fiscal = nil
      subject.error = "Timeout"
      expect(subject).to be_valid
    end
  end
end
