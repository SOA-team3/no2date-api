# frozen_string_literal: true

require 'roda'
require_relative 'app'

# rubocop:disable Metrics/BlockLength
module No2Date
  # Web controller for No2Date API
  class Api < Roda
    route('appointments') do |routing|
      unauthorized_message = { message: 'Unauthorized Request' }.to_json
      routing.halt(403, unauthorized_message) unless @auth_account

      @appt_route = "#{@api_root}/appointments"
      # if the "account" is directing to "appointments"
      routing.on String do |appt_id|
        # account = Account.first(username: @auth_account['username'])
        @req_appointment = Appointment.first(id: appt_id)

        # GET api/v1/appointments/[ID]
        routing.get do
          appointment = GetAppointmentQuery.call(
            account: @auth_account, appointment: @req_appointment
          )

          { data: appointment }.to_json
        rescue GetAppointmentQuery::ForbiddenError => e
          routing.halt 403, { message: e.message }.to_json
        rescue GetAppointmentQuery::NotFoundError => e
          routing.halt 404, { message: e.message }.to_json
        rescue StandardError => e
          puts "FIND APPOINTMENT ERROR: #{e.inspect}"
          routing.halt 500, { message: 'API server error' }.to_json
        end

        routing.on('participants') do
          # PUT api/v1/appointments/[appt_id]/participants
          routing.put do
            req_data = JSON.parse(routing.body.read)

            participant = AddParticipant.call(
              account: @auth_account,
              appointment: @req_appointment,
              part_email: req_data['email']
            )

            { data: participant }.to_json
          rescue AddParticipant::ForbiddenError => e
            routing.halt 403, { message: e.message }.to_json
          rescue StandardError
            routing.halt 500, { message: 'API server error' }.to_json
          end

          # DELETE api/v1/projects/[proj_id]/participants
          routing.delete do
            req_data = JSON.parse(routing.body.read)
            participant = RemoveParticipant.call(
              req_username: @auth_account.username,
              part_email: req_data['email'],
              project_id: proj_id
            )

            { message: "#{participant.username} removed from appointment",
              data: participant }.to_json
          rescue RemoveParticipant::ForbiddenError => e
            routing.halt 403, { message: e.message }.to_json
          rescue StandardError
            routing.halt 500, { message: 'API server error' }.to_json
          end
        end
      end

      routing.is do
        # GET api/v1/appointments
        routing.get do
          # account = Account.first(username: @auth_account['username'])
          appointments = AppointmentPolicy::AccountScope.new(@auth_account).viewable

          JSON.pretty_generate(data: appointments)
        rescue StandardError
          routing.halt 403, { message: 'Could not find any appointments' }.to_json
        end

        # POST api/v1/appointments
        routing.post do
          new_data = JSON.parse(routing.body.read)
          # account = Account.first(username: @auth_account['username'])
          new_appt = @auth_account.add_owned_appointment(new_data)

          response.status = 201
          response['Location'] = "#{@appt_route}/#{new_appt.id}"
          { message: 'Appointment saved', data: new_appt }.to_json
        rescue Sequel::MassAssignmentRestriction
          Api.logger.warn "MASS-ASSIGNMENT: #{new_data.keys}"
          routing.halt 400, { message: 'Illegal Attributes' }.to_json
        rescue StandardError => e
          Api.logger.error "UNKNOWN ERROR: #{e.message}"
          routing.halt 500, { message: 'Unknown server error' }.to_json
        end
      end
    end
  end
end