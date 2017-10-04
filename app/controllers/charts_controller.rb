class ChartsController < ApplicationController
   skip_before_action :authorize

   def set_page
      @page = :reports
   end

   def index
      @data = nil

      @class = params[:class]
      @class = "any" if @class.nil?
      @library = params[:library]
      @library = "any" if @library.nil?
      @sys = params[:sys]
      @sys = "any" if @sys.nil?
      @subclass = params[:subclass]
      @subclass = "any" if @subclass.nil?
      @show_settings = ( @subclass != "any" || @class != "any" || @sys != "any" || @library != "any")

      if params[:type].nil?
         @chart_title = "Hit Rate Error"
         @show_settings = false
      else
         if params[:type] == "top25"
            @chart_title = "Top 25 Hit Rates"
            @show_settings = false
         elsif params[:type] == "bottom25"
            @chart_title = "Bottom 25 Hit Rates"
            @show_settings = false
         else
            @chart_title =  "Hit Rates per #{ params[:type].capitalize}"
         end
      end

      if params[:type] == "intervention-distribution"
         @data = Report.intervention_distribution
      elsif params[:type] == "top25"
         @data = Report.hit_rate_extremes(:top)
      elsif params[:type] == "bottom25"
         @data = Report.hit_rate_extremes(:bottom)
      elsif params[:type] == "library"
         @data = Report.lib_hit_rate( @class )
      elsif params[:type] == "class"
         @data = Report.classification_hit_rate( @library, @sys )
      elsif params[:type] == "subclass"
         @data = Report.subclassification_hit_rate( @library, @sys, @class)
      elsif params[:type] == "decade"
         @data = Report.decade_hit_rate( @library, @class, @subclass)
      end
   end
end
