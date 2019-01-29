require 'rails_helper'

describe ReactivateAccountSession do
  let(:user) { build(:user) }
  let(:user_session) { {} }

  before do
    @reactivate_account_session = ReactivateAccountSession.new(
      user: user,
      user_session: user_session,
    )
  end

  describe '#clear' do
    it 'deletes the reactivate account session object from user_session' do
      expect(user_session).to have_key(:reactivate_account)

      @reactivate_account_session.clear

      expect(user_session).to be_empty
    end
  end

  describe '#start' do
    it 'sets the session object `active` flag to true' do
      @reactivate_account_session.start
      expect(user_session[:reactivate_account][:active]).to be(true)
    end
  end

  describe '#started?' do
    it 'initializes set to false' do
      expect(@reactivate_account_session.started?).to be(false)
    end

    it 'returns a boolean if the account reactivate flow has started or not' do
      @reactivate_account_session.start
      expect(@reactivate_account_session.started?).to be(true)
    end
  end

  describe '#suspend' do
    it 'sets the reactivate account object back to its defaults' do
      pii = {}

      @reactivate_account_session.start
      @reactivate_account_session.store_decrypted_pii(pii)

      expect(@reactivate_account_session.started?).to be(true)
      expect(@reactivate_account_session.personal_key?).to be(true)
      expect(@reactivate_account_session.decrypted_pii).to be(pii)

      @reactivate_account_session.suspend

      expect(@reactivate_account_session.started?).to be(false)
      expect(@reactivate_account_session.personal_key?).to be(false)
      expect(@reactivate_account_session.decrypted_pii).to eq(nil)
    end
  end

  describe '#store_decrypted_pii' do
    it 'stores the supplied object in the session and toggles `personal_key` flag' do
      pii = {}
      @reactivate_account_session.store_decrypted_pii(pii)
      account_reactivation_obj = user_session[:reactivate_account]
      expect(account_reactivation_obj[:personal_key]).to be(true)
      expect(account_reactivation_obj[:pii]).to eq(pii)
    end
  end

  describe '#personal_key?' do
    it 'defaults to false' do
      expect(@reactivate_account_session.personal_key?).to be(false)
    end

    it 'returns a boolean indicating if the user hsa validated their personal key' do
      @reactivate_account_session.store_decrypted_pii({})
      expect(@reactivate_account_session.personal_key?).to be(true)
    end
  end

  describe '#decrypted_pii' do
    it 'returns nil as a default' do
      expect(@reactivate_account_session.decrypted_pii).to eq(nil)
    end

    it 'returns the pii stored in the session' do
      pii = {}
      @reactivate_account_session.store_decrypted_pii(pii)

      expect(@reactivate_account_session.decrypted_pii).to eq(pii)
    end
  end
end
