require 'yaml'

Puppet::Functions.create_function(:'pxe::enc_lookup') do
  dispatch :enc_lookup do
    param 'Stdlib::Fqdn', :hostname
  end

  def enc_lookup(hostname)
    node_terminus = Puppet.settings[:node_terminus]
    if node_terminus.to_s == 'exec'
      external_nodes = Puppet.settings[:external_nodes]
      cmd = "#{external_nodes} #{hostname}"

      begin
        cmdout = Puppet::Util::Execution.execute(cmd)
        return {} if cmdout.nil?
        return {} if cmdout.empty?
      rescue Puppet::ExecutionFailure => detail
        Puppet.debug "Execution of #{cmd} command failed: #{detail}"
        return {}
      end

      YAML.safe_load(cmdout.strip)
    else
      {}
    end
  end
end
