# frozen_string_literal: true

require 'json'
require 'sequel'

module No2Date
  # Models a meeting
  class Meeting < Sequel::Model
    one_to_many :schedules
    plugin :association_dependencies, schedules: :destroy

    plugin :timestamps

    # rubocop:enable Metrics/MethodLength
    def to_json(options = {})
    JSON(
      {
        data: {
          type: 'meeting',
          attributes: {
            id: id,
            name: name,
            url: url,
            owner: owner
          }
        }
      }, options
    )
    end
    # rubocop:enable Metrics/MethodLength
  end
end