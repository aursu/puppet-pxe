Puppet::Type.newtype(:pxe_host) do
  @doc = 'PXE host declaration'

  #   <% if @boot_kernel -%>
  #   set kernel='<%= @boot_kernel %>'
  #   <% end -%>
  #   <% if @boot_initimg -%>
  #   set initimg='<%= @boot_initimg %>'
  #   <% end -%>
  #   <% if @centos %>
  #   <%   if [ 5, 6 ].include?(@major_version) -%>
  #   set options='ksdevice=<%= @interface %> ks=http://<%= @install_server %>/ks/<%= @ks_filename %>'
  #   <%   else -%>
  #   # https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/installation_guide/chap-anaconda-boot-options
  #   set options='ip=dhcp ksdevice= inst.ks=http://<%= @install_server %>/ks/<%= @ks_filename %><% if @disable_biosdevname %> net.ifnames=0 biosdevname=0<% end %>'
  #   <%   end -%>
  #   <% else -%>
  #   set options='ip=dhcp<% if @disable_biosdevname %> net.ifnames=0 biosdevname=0<% end %>'
  #   <% end -%>

  # #!ipxe
  # kernel http://<%= @install_server %>/<%= @boot_kernel %> ip=dhcp ksdevice= \
  #        inst.ks=http://<%= @install_server %>/ks/<%= @ks_filename %><% if @disable_biosdevname %> net.ifnames=0 biosdevname=0<% end %>
  # initrd http://<%= @install_server %>/<%= @boot_initimg %>
  # boot

  newparam(:name, namevar: true) do
    desc 'PXE host declaration name'

    validate do |val|
      raise Puppet::ParseError, _('pxe_host :name must be a string') unless val.is_a?(String)
      raise Puppet::ParseError, _('pxe_host :name must be a valid hostname') unless resource.validate_hostname(val)
    end

    munge do |val|
      val.downcase
    end
  end

  newproperty(:centos) do
    desc 'Whether config is default CentOS installation'

    defaultto { '' }

    validate do
      true
    end

    munge do |val|
      val
    end

    def retrieve; end
  end

  newproperty(:kernel) do
    desc 'Kernel parameter inside PXE host config'

    defaultto { '' }

    validate do
      true
    end

    munge do |val|
      val
    end

    def retrieve; end
  end

  def validate_hostname(host)
    return nil unless host
    %r{^([a-z0-9]+(-[a-z0-9]+)*\.?)+[a-z0-9]{2,}$} =~ host.downcase
  end
end
