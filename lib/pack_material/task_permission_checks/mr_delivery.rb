# frozen_string_literal: true

module PackMaterialApp
  module TaskPermissionCheck
    class MrDelivery < BaseService # rubocop:disable Metrics/ClassLength
      attr_reader :task, :entity
      # @param [Symbol] task
      # @param [Integer] delivery_id
      # @param [Hash] opts ex: { sku_ids: 1, loc_id: 1 }
      def initialize(task, delivery_id = nil, opts: {}, current_user: nil)
        @task   = task
        @repo   = ReplenishRepo.new
        @id     = delivery_id
        @entity = @id ? @repo.find_mr_delivery(@id) : nil
        @opts   = opts
        @user   = current_user
      end

      def call # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
        return failed_response 'Delivery record not found' unless @entity || task == :create

        case task
        when :create
          create_check
        when :update, :delete
          mutable_check
        when :accept_over_supply
          accept_over_supply_check
        when :accept_qty_difference
          accept_qty_difference_check
        when :review
          review_check
        when :review_required
          review_required_check
        when :has_on_consignment_items
          on_consignment_items_check
        when :verify
          verify_check
        when :putaway
          putaway_check
        when :add_invoice
          add_invoice_check
        when :complete_invoice
          complete_invoice_check
        when :bsa_in_progress_check
          bsa_in_progress_check
        else
          raise ArgumentError, "Task \"#{task}\" is unknown for #{self.class}"
        end
      end

      private

      def create_check
        all_ok
      end

      def mutable_check
        return failed_response "Verified delivery can not be #{task}d" if verified?
        return failed_response "Accepted delivery can not be #{task}d" if over_supply_accepted?

        all_ok
      end

      def accept_over_supply_check
        fail_message = prerequisite_check
        fail_message ||= 'User is not allowed to review Deliveries' unless can_user_review?
        fail_message ||= 'Delivery Over Supply is already accepted' if over_supply_accepted?
        fail_message ||= 'Delivery does not have any over supplied items' unless over_supply?
        return failed_response(fail_message) if fail_message

        all_ok
      end

      def accept_qty_difference_check
        fail_message = prerequisite_check
        fail_message ||= 'User is not allowed to review Deliveries' unless can_user_review?
        fail_message ||= 'Delivery Quantity Difference is already accepted' if qty_difference_accepted?
        fail_message ||= 'Delivery does not have any items with quantity differences' unless qty_difference?
        return failed_response(fail_message) if fail_message

        all_ok
      end

      def verify_check
        fail_message = prerequisite_check
        fail_message ||= 'Delivery must be reviewed' if review_required?
        return failed_response(fail_message) if fail_message

        all_ok
      end

      def review_check
        fail_message = prerequisite_check
        fail_message ||= 'Nothing to review' unless review_required?
        fail_message ||= 'User is not allowed to review Deliveries' unless can_user_review?
        return failed_response(fail_message) if fail_message

        all_ok
      end

      def review_required_check
        fail_message = prerequisite_check
        fail_message ||= 'Nothing to review' unless review_required?
        return failed_response(fail_message) if fail_message

        all_ok
      end

      def prerequisite_check # rubocop:disable Metrics/CyclomaticComplexity
        fail_message = verified? ? 'Delivery is already verified' : nil
        fail_message ||= 'Delivery has no items' if no_items?
        fail_message ||= 'Delivery has incomplete items' if incomplete_items?
        fail_message ||= 'Delivery has invalid on consignment type items without batches' if invalid_on_consignment_items?
        fail_message ||= 'Delivery has items without batches' if items_without_batches?
        fail_message ||= 'Delivery batch quantities do not equate to item quantities where applicable' if item_quantities_ignored?
        fail_message
      end

      def putaway_check
        return failed_response('Delivery Putaway has already been completed') if putaway_completed?
        return failed_response('Delivery has not been verified') unless verified?

        all_ok
      end

      def bsa_in_progress_check
        return failed_response('Bulk Stock Adjustment in progress') if bsa_in_progress?

        all_ok
      end

      def add_invoice_check
        return failed_response('Delivery has not been verified') unless verified?

        all_ok
      end

      def complete_invoice_check
        return failed_response('Delivery Purchase Invoice has already been completed') if invoice_completed?
        return failed_response('Delivery has items without prices') if items_without_prices?
        return failed_response('Purchase Invoice incomplete') if invoice_incomplete?

        all_ok
      end

      def on_consignment_items_check
        return failed_response('Delivery does not have items on consignment') unless @repo.on_consignment_items(@id)

        all_ok
      end

      def review_required?
        (over_supply? && !over_supply_accepted?) || (qty_difference? && !qty_difference_accepted?)
      end

      def putaway_completed?
        @entity.putaway_completed
      end

      def invoice_completed?
        @entity.invoice_completed
      end

      def invoice_incomplete?
        @entity.supplier_invoice_ref_number.nil? || @entity.supplier_invoice_date.nil?
      end

      def verified?
        @entity.verified
      end

      def no_items?
        @repo.mr_delivery_items(@id).empty?
      end

      def items_without_batches?
        @repo.items_without_batches(@id)
      end

      def items_without_prices?
        @repo.items_without_prices(@id)
      end

      def incomplete_items?
        @repo.incomplete_items(@id)
      end

      def invalid_on_consignment_items?
        @repo.invalid_on_consignment_items(@id)
      end

      def item_quantities_ignored?
        !@repo.batch_quantities_match(@id)
      end

      def bsa_in_progress?
        bsa_repo = BulkStockAdjustmentRepo.new
        bsa_repo.any_in_progress?(@opts)
      end

      def over_supply_accepted?
        @entity.accepted_over_supply
      end

      def over_supply?
        @repo.items_with_over_supply(@id)
      end

      def qty_difference_accepted?
        @entity.accepted_qty_difference
      end

      def qty_difference?
        @repo.items_with_qty_difference(@id)
      end

      def can_user_review?
        return false unless @user

        Crossbeams::Config::UserPermissions.can_user?(@user, :delivery, :review)
      end
    end
  end
end
