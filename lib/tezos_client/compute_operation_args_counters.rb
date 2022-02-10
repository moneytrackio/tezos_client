# frozen_string_literal: true

class TezosClient
  class ComputeOperationArgsCounters
    def initialize(pending_operations:, operation_args:)
      @pending_operations = pending_operations
      @operation_args = Marshal.load(Marshal.dump(operation_args)) # deep copy of the object
    end

    def call
      max_counter_by_source = group_by_max_counter(
        @pending_operations["applied"].map { |operation| operation["contents"] }
                                      .flatten
                                      .select { |content| content.has_key?("source") }
      )

      @operation_args.each do |operation|
        source = operation[:source]
        # do not update the counter of an operation not present in the mempool
        next unless max_counter_by_source[source]

        operation[:counter] = (max_counter_by_source[source].to_i + 1).to_s
        # update max_counter_by_source as if the current operation was added to the mempool
        max_counter_by_source[source] = operation[:counter]
      end

      @operation_args
    end

    private
      def group_by_max_counter(arr)
        arr.map(&:with_indifferent_access)
           .group_by { |hsh| hsh[:source] }
           .transform_values do |contents|
          contents.max_by { |content| content[:counter].to_i }[:counter]
        end
      end
  end
end
