# frozen_string_literal: true

require 'spec_helper'

describe 'pxe::client_config' do
  let(:title) { 'namevar' }
  let(:params) do
    {
      install_server: 'bsys.domain.tld',
    }
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }

      it {
        is_expected.to contain_file('/var/lib/pxe/namevar.cfg')
          .with_content(%r{^set options='ip=dhcp ksdevice= inst.ks=http://bsys.domain.tld/ks/default.cfg net.ifnames=0 biosdevname=0'$})
      }

      context "with CentOS version 10-20250123.0" do
        let(:params) do
          super().merge(
            osrelease: '10-20250123.0',
          )
        end

        it { is_expected.to compile }

        it {
          is_expected.to contain_file('/var/lib/pxe/namevar.cfg')
            .with_content(%r{^set kernel='/boot/centos/10/os/x86_64/images/pxeboot/vmlinuz'$})
        }
      end

      context "with CentOS version 10-stream" do
        let(:params) do
          super().merge(
            osrelease: '10-stream',
          )
        end

        it { is_expected.to compile }

        it {
          is_expected.to contain_file('/var/lib/pxe/namevar.cfg')
            .with_content(%r{^set kernel='/boot/centos/10-stream/os/x86_64/images/pxeboot/vmlinuz'$})
        }
      end
    end
  end
end
