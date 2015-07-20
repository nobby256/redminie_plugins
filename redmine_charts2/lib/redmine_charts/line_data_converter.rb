module RedmineCharts
  module LineDataConverter

    include Redmine::I18n

    def self.convert(chart, data)
      index = 0


      data[:sets].each do |set|
        #[0]�̓V���[�Y��
        line = OpenFlashChart::Line.new
        line.text = set[0]
        line.width = 2
        line.colour = RedmineCharts::Utils.color(index)
        line.dot_size =  2

        j = -1

        #[1]�̓f�[�^�̔z��
        #
        #�l���z��̏ꍇ
        #[1][x][0]�͒l
        #[1][x][1]�̓c�[���`�b�v
        #[1][x][2]��???
        #
        #�l���z��ł͂Ȃ��ꍇ
        #[1][x]�͒l
        vals = set[1].collect do |v|
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
    end

  end
end
