# frozen_string_literal: true

module PackMaterialApp
  module TaskPermissionCheck
    class VehicleJobUnit < BaseService
      attr_reader :task, :entity
      def initialize(task, vehicle_job_unit_id = nil)
        @task = task
        @repo = TripsheetsRepo.new
        @id = vehicle_job_unit_id
        @entity = @id ? @repo.find_vehicle_job_unit(@id) : nil
      end

      CHECKS = {
        create: :create_check,
        edit: :edit_check,
        delete: :delete_check
        # complete: :complete_check,
        # approve: :approve_check,
        # reopen: :reopen_check
      }.freeze

      def call
        return failed_response 'Record not found' unless @entity || task == :create

        check = CHECKS[task]
        raise ArgumentError, "Task \"#{task}\" is unknown for #{self.class}" if check.nil?

        send(check)
      end

      private

      def create_check
        all_ok
      end

      def edit_check
        # return failed_response 'VehicleJobUnit has been completed' if completed?

        all_ok
      end

      def delete_check
        # return failed_response 'VehicleJobUnit has been completed' if completed?

        all_ok
      end

      # def complete_check
      #   return failed_response 'VehicleJobUnit has already been completed' if completed?

      #   all_ok
      # end

      # def approve_check
      #   return failed_response 'VehicleJobUnit has not been completed' unless completed?
      #   return failed_response 'VehicleJobUnit has already been approved' if approved?

      #   all_ok
      # end

      # def reopen_check
      #   return failed_response 'VehicleJobUnit has not been approved' unless approved?

      #   all_ok
      # end

      # def completed?
      #   @entity.completed
      # end

      # def approved?
      #   @entity.approved
      # end
    end
  end
end
