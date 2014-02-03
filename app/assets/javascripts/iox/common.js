$( function(){

  window.iox.publive = window.iox.publive || {};

  window.iox.publive.setupGrid = function( $elem, item_id, files_url, url ){

    //var treeSource = setupTreeSource( item );
    var treeview;

    var kGrid = $elem.kendoGrid({
        dataSource: {
            type: "json",
            transport: {
              read:  function readFiles( options ){
                $.getJSON( url+'/'+item_id+'/images', options.success );
              },
              update: function updateFile( options ){
                var model = setupFileModel( options );
                $.ajax({ 
                  url: files_url+'/'+model.id,
                  type: 'patch', 
                  dataType: 'json',
                  data: { image: model },
                  success: function( json ){ kGrid.data('kendoGrid').dataSource.read(); iox.flash.rails( json.flash ); },
                  error: function( json ){ kGrid.data('kendoGrid').dataSource.read(); iox.flash.rails( json.flash ); }
                });
              },
              destroy: function destroyFile( options ){
                var model = setupFileModel( options );
                $.ajax({ 
                  url: files_url+'/'+model.id, 
                  type: 'delete', 
                  dataType: 'json',
                  success: function( json ){ iox.flash.rails(json.flash); options.success(); },
                  error: function( json ){ iox.flash.rails(json.flash); options.error(); }
                });
              }
            },
            schema: {
              model: {
                id: 'id',
                fields: {
                  id: { type: "number", editable: false },
                  name: { type: "string" },
                  description: { type: "string" },
                  copyright: { type: "string" },
                  created_at: { type: 'date', editable: false },
                  content_type: { type: 'string', editable: false },
                  size: { type: 'integer', editable: false },
                  updater_name: { type: 'string', editable: false },
                  updated_at: { type: 'date', editable: false }
                }
              }
            },
            pageSize: 20,
            serverPaging: false,
            serverFiltering: false,
            serverSorting: false
        },
        height: $(window).height()-220,
        filterable: false,
        sortable: true,
        pageable: false,
        editable: 'popup',
        edit: function(e) {
          e.container.find('.k-edit-field[data-container-for="thumb_url"]').hide();
          e.container.find('label[for="thumb_url"]').parent().hide();
        },
        columns: [
          { field: "thumb_url", 
            title: I18n.t('webfile.preview'),
            width: 30,
            template: '<img src="#= thumb_url #" alt="image" />' },
          { field: 'name',
            title: I18n.t('webfile.name')
          },
          { field: 'copyright',
            title: I18n.t('webfile.copyright') },
          { field: 'description',
            title: I18n.t('webfile.description') },
          { field: 'updater_name',
            title: I18n.t('webfile.updated_by') },
          { field: 'updated_at',
            width: 160,
            editable: false,
            title: I18n.t('webfile.updated_at'),
            format: '{0:dd.MM.yyyy HH:mm}' },
          { field: 'content_type',
            editable: false,
            title: I18n.t('webfile.type') },
          { field: 'size',
            width: 100,
            title: I18n.t('webfile.size')+' Kb'},
          { width: 180,
            command:
            [ 'edit',
              { name: 'downloadFile',
                text: '<i class="icon-download"></i>',
                click: function(e){
                  var dataItem = this.dataItem($(e.currentTarget).closest("tr"));
                  window.open( dataItem.original_url )
                }
              },
              'destroy'
            ]
          }
        ]
    });

    treeview = $elem.data('kendoTreeView');

    $('#upload-file').fileupload({
      url: url+'/'+item_id+'/images',
      dataType: 'json',
      formData: {
        "authenticity_token": $('input[name="authenticity_token"]:first').val()
      },
      dragover: function( e ){
        $(this).closest('.select-files').addClass('drop-here');
      },
      done: function (e, data) {
        var file = data._response.result;
        var self = this;
        setTimeout( function(){
          $(self).closest('.select-files').find('.progress').hide();
          $(self).closest('.select-files').find('.progress .bar').css( 'width', 0 );
          $(self).closest('.select-files').find('.progress-num').fadeOut();
          $('#upload-file').show();
        }, 1000 );
        // reload dataSource
        kGrid.data('kendoGrid').dataSource.read();
      },
      fail: function( response, type, msg ){
        console.log( response, type, msg );
        iox.flash.alert( JSON.parse(response.responseText).errors.file[0] );
      },
      submit: function( e, data ){
        $('#upload-file').hide();
        $(self).closest('.select-files').find('.progress').show();
        $(this).closest('.select-files').find('.progress-num').fadeIn();
      },
      progressall: function (e, data) {
        var progress = parseInt(data.loaded / data.total * 100, 10);
        $(this).closest('.select-files').find('.progress-num').text( progress + '%' );
        $(this).closest('.select-files').find('.progress .bar').css( 'width', progress + '%' );
      }
    });

    $('#download-from-url').on('click', function(e){
      $(this).closest('.field-box').block();
      var self = this;
      e.preventDefault();
      $.ajax({ url: url+'/'+item_id+'/download_from_url',
        type: 'post',
        dataType: 'json',
        data: {
          description: $('input[name=image-description]').val(),
          copyright: $('input[name=image-copyright]').val(),
          download_url: $('input[name=image-url]').val()
        }
      }).done( function(json){
        $(self).closest('.field-box').unblock();
        iox.flash.rails( json.flash );
        imagesData.data.push( json.item );
        $('input[name=image-url]').val('');
        reloadPreview();
      });
    });


    function setupFileModel( options ){
      console.log(arguments);
      var model = options.data;
      return model;
    }

  };


});