# coding: utf-8
module PacketGen
  module Header
    class IKE
      
      # This class handles Key Exchange payloads, as defined in RFC 7296 §3.4
      #
      # A KE payload contains a generic payload header (see {Payload}) and some
      # specific fields:
      #                        1                   2                   3
      #    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
      #   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      #   | Next Payload  |C|  RESERVED   |         Payload Length        |
      #   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      #   |   Diffie-Hellman Group Num    |           RESERVED            |
      #   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      #   |                                                               |
      #   ~                       Key Exchange Data                       ~
      #   |                                                               |
      #   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      # These specific fields are:
      # * {#group_num} (type {Types::Int16}),
      # * {#reserved} (type {Types::Int16}),
      # * and {#data} (type {Types::String}).
      #
      # == Create a KE payload
      #   # Create a IKE packet with a KE payload
      #   pkt = PacketGen.gen('IP').add('UDP').add('IKE')
      #   # group name is taken from Transform::DH_* constants
      #   pkt.add('KE', group: 'MODP4096')
      #   # group number may also be used
      #   pkt.ke.group = 1
      # @author Sylvain Daubert
      class KE < Payload
        delete_field :content
        # @!attribute [r] group_num
        #  16-bit Diffie-Hellman Group Number
        #  @return [Integer]
        define_field_before :body, :group_num, Types::Int16
        # @!attribute reserved
        #  16-bit reserved field
        #  @return [Integer]
        define_field_before :body, :reserved, Types::Int16, default: 0
        # @!attribute data
        #  Key Exchange data
        #  @return [String]
        define_field_before :body, :data, Types::String

        def initialize(options={})
          super
          self.group = options[:group] if options[:group]
        end

        # Populate object from a string
        # @param [String] str
        # @return [self]
        def read(str)
          super
          hlen = self.class.new.sz
          plen = length - hlen
          data.read str[hlen, plen]
          body.read str[hlen+plen..-1]
          self
        end

        # Set group
        # @param [Integer,String] value may be a String taken from
        #   {Transform}+::DH_*+ constant names.
        # @return [Integer]
        def group=(value)
          group = case value
                  when Integer
                    value
                  else
                    cname = "DH_#{value}"
                    Transform.const_defined?(cname) ? Transform.const_get(cname) : nil
                  end
          raise ArgumentError, "unknown group #{value.inspect}" unless group
          self[:group_num].value = group
        end
      end
    end

    self.add_class IKE::KE
  end
end
