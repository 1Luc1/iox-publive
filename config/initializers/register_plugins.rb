# add plugins to iox-cms
Rails.configuration.iox.plugins ||= []


Rails.configuration.iox.plugins << Iox::Plugin.new( name: 'program_entries',
                                                    roles: [],
                                                    icon: 'icon-calendar',
                                                    path: '/iox/program_entries' )

Rails.configuration.iox.plugins << Iox::Plugin.new( name: 'ensembles',
                                                    roles: [],
                                                    icon: 'icon-asterisk',
                                                    path: '/iox/ensembles' )

Rails.configuration.iox.plugins << Iox::Plugin.new( name: 'people',
                                                    roles: [],
                                                    icon: 'icon-group',
                                                    path: '/iox/people' )

Rails.configuration.iox.plugins << Iox::Plugin.new( name: 'venues',
                                                    roles: [],
                                                    icon: 'icon-map-marker',
                                                    path: '/iox/venues' )