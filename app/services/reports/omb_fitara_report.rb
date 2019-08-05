module Reports
  class OmbFitaraReport
    MOST_RECENT_MONTHS_COUNT = 2
    S3_BUCKET = Figaro.env.omb_fitara_bucket
    S3_FILENAME = Figaro.env.omb_fitara_filename
    OLDEST_TIMESTAMP = '2016-01-01 00:00:00'.freeze

    def call
      body = results_json
      if Rails.env.production? && S3_FILENAME
        Aws::S3::Resource.new.bucket(S3_BUCKET).object(S3_FILENAME).put(
          body: results_json, acl: 'private', content_type: 'application/json',
        )
      end
      body
    end

    private

    def results_json
      month, year = current_month
      counts = []
      MOST_RECENT_MONTHS_COUNT.times do
        counts << { month: "#{year}#{format('%02d', month)}", count: count_for_month(month, year) }
        month, year = previous_month(month, year)
      end
      { counts: counts }.to_json
    end

    def count_for_month(month, year)
      month, year = next_month(month, year)
      finish = "#{year}-#{month}-01 00:00:00"
      Funnel::Registration::RangeRegisteredCount.call(OLDEST_TIMESTAMP, finish)
    end

    def current_month
      today = Time.zone.today
      [today.strftime('%m').to_i, today.strftime('%Y').to_i]
    end

    def next_month(month, year)
      month += 1
      if month > 12
        month = 1
        year += 1
      end
      [month, year]
    end

    def previous_month(month, year)
      month -= 1
      if month.zero?
        month = 12
        year -= 1
      end
      [month, year]
    end
  end
end
