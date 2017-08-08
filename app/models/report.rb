class Report
   def self.intervention_distribution
      total = Intervention.all.count
      chart = { labels:[], data:[]}
      InterventionType.all.each do |t|
         c = InterventionDetail.where(intervention_type_id: t.id).count
         chart[:data] << c
         p = ((c.to_f/total.to_f)*100.0).round(1)
         chart[:labels] << "#{t.category.capitalize}: #{t.name.capitalize} (#{c}/#{total} #{p}%)"
      end
      return chart
   end
end
