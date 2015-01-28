# coding: utf-8

module IssueNoParentUpdatePatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)

    base.class_eval do
      unloadable

      #親/自分/子供の間でバージョンのつじつまを合わせる
      before_save :copy_fixed_version_id_to_children
      before_save :copy_estimated_hours_to_remaining_hours
      
      #親チケットの開始日/期日/優先度を独自に変更可能にする
      alias_method_chain :recalculate_attributes_for, :no_update
      alias_method_chain :safe_attributes=, :no_update
    end
  end

  module InstanceMethods

    def copy_fixed_version_id_to_children
      #新規作成、もしくは、親が変わった場合
      if new_record? || parent_id_changed?
        if self.parent_issue_id && !self.fixed_version_id
          #親が指定されていてかつ、バージョンが未指定の場合は
          #親と同じバージョンにする
          if @parent_issue.fixed_version_id
            self.fixed_version_id = @parent_issue.fixed_version_id
          end
        end
      end
      if !leaf? && fixed_version_id_changed?
          children.each do |child|
              child.fixed_version_id = self.fixed_version_id
              child.save!
          end
      end
    end

    def copy_estimated_hours_to_remaining_hours
      #新規作成時は画面では残工数の入力項目を非表示にしている為、
      #画面から入力した場合は残工数が!nilという状況は生まれない。
      #しかし、Import系のプラグインによって直接モデルを生成された
      #場合はその限りではない。
      #そのケースに限っては、もし残工数に値が入っていたのであれば
      #その値を有効値として利用する
      if new_record?
        if self.estimated_hours
          if !self.remaining_hours
            self.remaining_hours = self.estimated_hours
          end
        end
      end
    end

    def recalculate_attributes_for_with_no_update(issue_id)
      if issue_id && p = Issue.find_by_id(issue_id)

        # done ratio = weighted average ratio of leaves
        unless Issue.use_status_for_done_ratio? && p.status && p.status.default_done_ratio
          leaves_count = p.leaves.count
          if leaves_count > 0
            average = p.leaves.where("estimated_hours > 0").average(:estimated_hours).to_f
            if average == 0
              average = 1
            end
            done = p.leaves.joins(:status).
              sum("COALESCE(CASE WHEN estimated_hours > 0 THEN estimated_hours ELSE NULL END, #{average}) " +
                  "* (CASE WHEN is_closed = #{connection.quoted_true} THEN 100 ELSE COALESCE(done_ratio, 0) END)").to_f
            progress = done / (average * leaves_count)
            p.done_ratio = progress.round
          end
        end

        # remaining = sum of leaves remainings
        p.remaining_hours = p.leaves.sum(:remaining_hours).to_f
        p.remaining_hours = nil if p.remaining_hours == 0.0

        # ancestors will be recursively updated
        p.save(:validate => false)
      end
    end

    # Safely sets attributes
    # Should be called from controllers instead of #attributes=
    # attr_accessible is too rough because we still want things like
    # Issue.new(:project => foo) to work
    def safe_attributes_with_no_update=(attrs, user=User.current)
      return unless attrs.is_a?(Hash)
      attrs = attrs.dup

      # Project and Tracker must be set before since new_statuses_allowed_to depends on it.
      if (p = attrs.delete('project_id')) && safe_attribute?('project_id')
        if allowed_target_projects(user).where(:id => p.to_i).exists?
          self.project_id = p
        end
      end

      if (t = attrs.delete('tracker_id')) && safe_attribute?('tracker_id')
        self.tracker_id = t
      end

      if (s = attrs.delete('status_id')) && safe_attribute?('status_id')
        if new_statuses_allowed_to(user).collect(&:id).include?(s.to_i)
          self.status_id = s
        end
      end

      attrs = delete_unsafe_attributes(attrs, user)
      return if attrs.empty?

      unless leaf?
        #チケットツリーの末端でない場合は、進捗率と残工数は変更できない
        #逆に通常変更できないはずの開始日/期日/予定工数はいつでも変更可能
        attrs.reject! {|k,v| %w(done_ratio remaining_hours).include?(k)}
      end

      if attrs['parent_issue_id'].present?
        s = attrs['parent_issue_id'].to_s
        unless (m = s.match(%r{\A#?(\d+)\z})) && (m[1] == parent_id.to_s || Issue.visible(user).exists?(m[1]))
          @invalid_parent_issue_id = attrs.delete('parent_issue_id')
        end
      end

      if attrs['custom_field_values'].present?
        editable_custom_field_ids = editable_custom_field_values(user).map {|v| v.custom_field_id.to_s}
        # TODO: use #select when ruby1.8 support is dropped
        attrs['custom_field_values'] = attrs['custom_field_values'].reject {|k, v| !editable_custom_field_ids.include?(k.to_s)}
      end

      if attrs['custom_fields'].present?
        editable_custom_field_ids = editable_custom_field_values(user).map {|v| v.custom_field_id.to_s}
        # TODO: use #select when ruby1.8 support is dropped
        attrs['custom_fields'] = attrs['custom_fields'].reject {|c| !editable_custom_field_ids.include?(c['id'].to_s)}
      end

      # mass-assignment security bypass
      assign_attributes attrs, :without_protection => true
    end
  end
end
