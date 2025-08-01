require 'mailjet'

namespace :iox do
  namespace :newsletter do

    desc "send newsletter for premiers within next month"
    task :send_premieres => :environment do
      logger = Logger.new("#{Rails.root}/log/newsletter.log")
      @program_events = Iox::ProgramEvent.show_in_newsletter.next_month.order(:starts_at)
      number_of_program_events = @program_events.count
      logger.info "Start sending newsletter with program_events #{number_of_program_events}"

      # only proceed if there are events
      if number_of_program_events > 0
        # setup defaults
        domain_name = "https://" + Rails.configuration.iox.domain_name
        counter = 0
        rows = []
        columns = []

        # loop over all events and build variables
        @program_events.each do |event|
          # update counter for columns
          if counter > 1
            rows << {"columns" => columns}
            columns = []
            counter = 0
          end

          # build further dates
          dates = []
          event.program_entry.next_event_dates(event).each do |date_event|
            dates << date_event.starts_at.strftime('%d.%m.%Y')
          end

          # make variables
          columns << { "title" => event.program_entry.title,
            "venue" => event.venue.name,
            "img" => domain_name + event.program_entry.images.first.file.url(:original, timestamp: false),
            "text" => event.program_entry.description,
            "contributors" => event.program_entry.crew.map{ |person| person.name }.join(", "),
            "dates" => (dates.empty? ? "" : "weitere Termine: ") + dates.join(", "),
            "ics" => "#{domain_name}/#{event.id}/theaterspielplan.ics"
          }

          counter = counter + 1
        end
        # out of loop -> add last columns
        rows << {"columns" => columns}

        year = Date.today.year
        month = I18n.t("date.month_names")[(DateTime.now + 1.month).month]
        
        # need to use mailjet v3.1 to use send method
        Mailjet.configure do |config|
          config.api_version = "v3.1"
        end

        # send newsletter
        variable = Mailjet::Send.create(messages: [{
          'From'=> {
              'Email'=> ENV['MAILJET_TSP_NEWSLETTER_LIST_MAIL'],
              'Name'=> 'Freietheater'
          },
          'To'=> [
              {
                  'Email'=> ENV['MAILJET_TSP_NEWSLETTER_LIST_MAIL'],
                  'Name'=> "Theaterspielplan Newsletter"
              }
          ],
          'TemplateID'=> ENV['MAILJET_TSP_NEWSLETTER_TEMPLATE_ID'],
          'TemplateLanguage'=> true,
          'TemplateErrorReporting' => {
            'Email' => ENV['ADMIN_USER_EMAIL'],
            'Name' => 'Admin'
          },
          'Subject' => "Newsletter Theaterspielplan #{month}/#{year}",
          'Variables'=> {
                "rows" => rows,
                "year" => "#{year}",
                "month" => "#{month}"
                },
          'CustomCampaign' => "Theaterspielplan Newsletter #{month}/#{year}"
          }]
        )

        logger.info "Mailjet Message: #{variable.attributes['Messages']}"

      end
    end
  end
end