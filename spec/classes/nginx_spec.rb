# frozen_string_literal: true

require 'spec_helper'

describe 'pxe::nginx' do
  let(:pre_condition) { "class { 'nginx': }" }

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:params) do
        {
          server_name: 'install.domain.tld',
          resolver: ['192.168.1.1']
        }
      end

      it { is_expected.to compile }
    end
  end
end
