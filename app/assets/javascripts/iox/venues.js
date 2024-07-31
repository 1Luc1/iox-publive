function setupVenue( venue, i18n ){

  $('#venue_logo').fileupload({
    dataType: 'json',
    formData: {
      "authenticity_token": $('input[name="authenticity_token"]:first').val()
    },
    done: function (e, data) {
      var logo = data._response.result[0];
      $('.logo[data-venue-id='+venue.id+']').attr('src', logo.thumbnail_url);
    }
  });


  var markers = new L.LayerGroup();

  if( venue.lat && venue.lng && venue.lat > 0 && venue.lng > 0 ){
    L.marker([venue.lat,venue.lng]).bindPopup(i18n.is_here).addTo(markers);
  } else if( venue.street && venue.street.length > 0 && venue.city.length > 0 ){
    $.getJSON( "http://nominatim.openstreetmap.org/search?q="+encodeURI(venue.street+'+'+venue.city+'+'+venue.country||'Austria')+"&format=json&polygon=1&addressdetails=1", function( json ){
      if( json.length > 0 ){
        $('#guessed-locations-list').html('');
        $('#selectLocationModal .loading').hide();
        json.forEach( function( item ){
          $('#guessed-locations-list').append(
            $('<li/>').attr('data-lat', item.lat).attr('data-lon', item.lon).append(
              $('<strong class="title"/>').text( item.display_name )
            ).append('<br/>').append(
              $('<em/>').text( item.address.pedestrian + ' ' + item.address.house_number + ', ' + item.address.postcode + ' ' + item.address.city + ', ' + item.address.country )
            )
          );
        });

        new iox.Win({ content: $('#selectLocationModal').html(), completed: function($win){

          $win.find('#guessed-locations-list li').on('click', function(e){
            $(this).toggleClass('selected');
          });
          $win.find('.btn-primary').on('click', function(e){
            if( $win.find('#guessed-locations-list li').length === 1 )
              $win.find('#guessed-locations-list li:first').addClass('selected');
            if( $win.find('#guessed-locations-list .selected').length < 1 )
              return;
            $('#venue_lat').val( $win.find('#guessed-locations-list .selected').attr('data-lat') );
            $('#venue_lng').val( $win.find('#guessed-locations-list .selected').attr('data-lon') );
            //$('.iox-form:visible').submit();
            iox.Win.closeVisible();
          });

          }
        });

      }

    });
  }

  var latlng = ((venue.lat && venue.lng) ? [venue.lat,venue.lng] : [47.425, 14.59]);

  setTimeout( function(){
    window.map = L.map('map', {
      center: latlng,
      zoom: ((venue.lat && venue.lng) ? '16' : '7'),
      layers: [markers]
    });

    L.tileLayer('https://{s}.tile.osm.org/{z}/{x}/{y}.png', {
        attribution: 'Map data &copy; <a href="https://openstreetmap.org">OpenStreetMap</a> contributors',
        maxZoom: 18
    }).addTo(window.map);

    $(document).on('click', '.save-new-marker', function(){
      $('#venue_lat').val( $(this).attr('data-lat'));
      $('#venue_lng').val( $(this).attr('data-lng'));
      $('.iox-form').submit();
    });

    window.map
      .on('click', function(e){
        console.log(e.latlng);
        L.popup()
          .setLatLng(e.latlng)
          .setContent(i18n.set_as_location+" <a href='#' data-lat='"+e.latlng.lat+"' data-lng='"+e.latlng.lng+"' class='save-new-marker'>"+i18n.save+"</a>?")
          .openOn(window.map);
      });
    }, 500);

}