module SessionsHelper
  def log_in_vnu
    begin
      agent = Mechanize.new
      page = agent.get Settings.base_url
      form = page.forms.first
      form["LoginName"] = params[:session][:str_id]
      form["Password"] = params[:session][:password]
      result = form.submit

      stringio = StringIO.new
      agent.cookie_jar.save(stringio, session: true)
      cookies = stringio.string
      session[:login_cookies] = cookies
      result
    rescue Mechanize::ResponseCodeError => e
    end
  end

  def get_groups
    current_user.courses.each do |course|
      if course.group.nil?
        group = course.create_group(course_id: course.id)
      else
        group = course.group
      end

      current_user.user_groups.find_or_create_by(group_id: group.id)
    end
  end

  def get_student_name(page)
    student_info = page.search("span.user-name").text.strip
    student_info[10..40].strip
  end

  def log_in(page)
    str_id = params[:session][:str_id]
    name = get_student_name page
    user = User.find_by_str_id str_id
    user = User.create str_id: str_id, name: name if user.nil?
    session[:str_id] = user.str_id
    cookies.signed[:str_id] = user.str_id
    crawl_data_from_list
    get_groups
  end

  def log_out
    session.delete :str_id
  end

  def logged_in?
    session[:str_id].present?
  end

  def current_user
    User.find_by_str_id session[:str_id]
  end
end
