module ResourceThis # :nodoc:
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def resource_this(options = {})
      options.assert_valid_keys(:class_name, :will_paginate, :sort_method, :nested)

      singular_name         = controller_name.singularize
      singular_name         = options[:class_name].downcase.singularize unless options[:class_name].nil?
      class_name            = options[:class_name] || singular_name.camelize
      plural_name           = singular_name.pluralize
      will_paginate_index   = options[:will_paginate] || false
      url_string            = "@#{singular_name}"
      list_url_string       = "#{plural_name}_url"
      finder_base           = class_name
      
      unless options[:nested].nil?
        nested              = options[:nested].to_s.singularize
        nested_class        = nested.camelize
        url_string          = "#{nested}_#{singular_name}_url(" + [nested, singular_name].map { |route| "@#{route}"}.join(', ') + ')'
        list_url_string     = "#{nested}_#{plural_name}_url(@#{nested})"
        finder_base         = "@#{nested}.#{plural_name}"
        module_eval <<-"end_eval", __FILE__, __LINE__
          before_filter :load_#{nested}
        end_eval
      end
      
      #standard before_filters
      module_eval <<-"end_eval", __FILE__, __LINE__
        before_filter :load_#{singular_name}, :only => [ :show, :edit, :update, :destroy ]
        before_filter :load_#{plural_name}, :only => [ :index ]
        before_filter :new_#{singular_name}, :only => [ :new ]
        before_filter :create_#{singular_name}, :only => [ :create ]
        before_filter :update_#{singular_name}, :only => [ :update ]
        before_filter :destroy_#{singular_name}, :only => [ :destroy ]
      protected
      end_eval
      
      unless options[:nested].nil?
        module_eval <<-"end_eval", __FILE__, __LINE__
          def load_#{nested}
            @#{nested} = #{nested_class}.find(params[:#{nested}_id])
          end
        end_eval
      end
      
      module_eval <<-"end_eval", __FILE__, __LINE__
        def load_#{singular_name}
          @#{singular_name} = #{finder_base}.find(params[:id])
        end
        
        def new_#{singular_name}
          @#{singular_name} = #{finder_base}.new
        end
        
        def create_#{singular_name}
          @#{singular_name} = #{finder_base}.new(params[:#{singular_name}])
          @created = @#{singular_name}.save
        end
        
        def update_#{singular_name}
          @updated = @#{singular_name}.update_attributes(params[:#{singular_name}])
        end
        
        def destroy_#{singular_name}
          @#{singular_name} = @#{singular_name}.destroy
        end
      end_eval
            
      #TODO: add sorting customizable by subclassed controllers      
      if will_paginate_index
        module_eval <<-"end_eval", __FILE__, __LINE__
          def load_#{plural_name}
            @#{plural_name} = #{finder_base}.paginate(:page => params[:page])
          end
        end_eval
      else
        module_eval <<-"end_eval", __FILE__, __LINE__
          def load_#{plural_name}
            @#{plural_name} = #{finder_base}.find(:all)
          end
        end_eval
      end

      module_eval <<-"end_eval", __FILE__, __LINE__
      public
        def index
          respond_to do |format|
            format.html
            format.xml  { render :xml => @#{plural_name} }
            format.js
          end
        end

        def show          
          respond_to do |format|
            format.html
            format.xml  { render :xml => @#{singular_name} }
            format.js
          end
        end

        def new          
          respond_to do |format|
            format.html { render :action => :edit }
            format.xml  { render :xml => @#{singular_name} }
            format.js
          end
        end

        def create
          respond_to do |format|
            if @created
              flash[:notice] = '#{class_name} was successfully created.'
              format.html { redirect_to #{url_string} }
              format.xml  { render :xml => @#{singular_name}, :status => :created, :location => #{url_string} }
              format.js
            else
              format.html { render :action => :new }
              format.xml  { render :xml => @#{singular_name}.errors, :status => :unprocessable_entity }
              format.js
            end
          end
        end 

        def edit
          respond_to do |format|
            format.html
            format.js
          end
        end

        def update
          respond_to do |format|
            if @updated
              flash[:notice] = '#{class_name} was successfully updated.'
              format.html { redirect_to #{url_string} }
              format.xml  { head :ok }
              format.js
            else
              format.html { render :action => :edit }
              format.xml  { render :xml => @#{singular_name}.errors, :status => :unprocessable_entity }
              format.js
            end
          end
        end

        def destroy          
          respond_to do |format|
            format.html { redirect_to #{list_url_string} }
            format.xml  { head :ok }
            format.js
          end
        end
      end_eval
    end
  end
end
