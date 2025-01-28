# frozen_string_literal: true

require 'spec_helper'

describe 'pxe::centos' do
  let(:pre_condition) { "class { 'pxe': }" }
  let(:title) { '10-stream' }
  let(:params) do
    {}
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }

      ['9-stream', '10-stream', '10-20250123.0'].each do |centos|
        context "with CentOS version #{centos}" do
          let(:title) { centos }

          it { is_expected.to compile }
        end
      end
    end
  end
end
