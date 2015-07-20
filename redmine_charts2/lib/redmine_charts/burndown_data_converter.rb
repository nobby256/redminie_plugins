module RedmineCharts
  module BurndownDataConverter

    include Redmine::I18n

    def self.convert(chart, data)

      line_sets = data[:sets][0]
      bar_sets = data[:sets][1]
      
      index = 0
      
      line_sets.each do |graph_data|

          #graph_data[0]�̓f�[�^��
          line = OpenFlashChart::Line.new
          line.text = graph_data[0]
          line.width = 2
          line.colour = RedmineCharts::Utils.color(index)
          line.dot_size =  2

          j = -1

          #graph_data[1]�̓f�[�^�̔z��
          #
          #�l���z��̏ꍇ
          #graph_data[1][n][0]�͒l
          #graph_data[1][n][1]�̓c�[���`�b�v
          #graph_data[1][n][2]��???
          #
          #�l���z��ł͂Ȃ��ꍇ
          #graph_data[1][n]�͒l
          vals = graph_data[1].collect do |v|
            j += 1
            if v.is_a? Array
              d = OpenFlashChart::Base.new
              d.set_value(v[0])
              if v[2]
                d.dot_size = 4
              end
              d.set_colour(RedmineCharts::Utils.color(index))
              d.set_tooltip("#{v[1]}<br>#{data[:labels][j]}") unless v[1].nil?
              d
            else
              v
            end
          end

          line.values = vals

          chart.add_element(line)

          index += 1
      end


      bar_max = 0
      bar_sets.each do |graph_data|

          #graph_data[0]�̓f�[�^��
          bar = OpenFlashChart::Bar.new
          bar.attach_to_right_y_axis
          bar.text = graph_data[0]
          bar.colour = RedmineCharts::Utils.color(index)

          j = -1

          vals = graph_data[1].collect do |v|
            j += 1
            if v.is_a? Array
              d = OpenFlashChart::BarValue.new(v[0])
              #d.set_value(v[0])
              d.set_colour(RedmineCharts::Utils.color(index))
              d.set_tooltip("#{v[1]}<br>#{data[:labels][j]}") unless v[1].nil?
              bar_max = v[0] if v[0] > bar_max 
              d
            else
              bar_max = v if v > bar_max 
              v
            end
          end
          bar.values = vals
          chart.add_element(bar)

          index += 1

      end
      
      if bar_sets.size > 0
        y_axis_right_labels = 5
        y = OpenFlashChart::YAxis.new
        y.set_range(0,(bar_max*1.2).round,(bar_max/y_axis_right_labels).round)
        chart.y_axis_right = y
      end
      
    end


  end
end
