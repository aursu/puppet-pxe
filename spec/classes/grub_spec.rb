# frozen_string_literal: true

require 'spec_helper'

describe 'pxe::grub' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }

      if os_facts[:os]['family'] == 'RedHat'
        it {
          is_expected.to contain_file('/var/lib/tftpboot/boot/grub/grub.cfg')
            .with_content(%r{^set kernel='/boot/centos/10-stream/BaseOS/x86_64/os/images/pxeboot/vmlinuz'$})
        }
      elsif os_facts[:os]['family'] == 'Debian'
        it {
          is_expected.to contain_file('/srv/tftp/boot/grub/grub.cfg')
            .with_content(%r{^set kernel='/boot/ubuntu/noble/casper/vmlinuz'$})
        }
      end
    end
  end
end
