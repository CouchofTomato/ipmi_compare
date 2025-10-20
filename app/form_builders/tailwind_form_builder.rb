class TailwindFormBuilder < ActionView::Helpers::FormBuilder
  CHECK_BOX_CLASSES = ClassVariants.build(
    base: "col-start-1 row-start-1 appearance-none rounded-sm border border-gray-300 bg-white checked:border-indigo-600 checked:bg-indigo-600 indeterminate:border-indigo-600 indeterminate:bg-indigo-600 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600 disabled:border-gray-300 disabled:bg-gray-100 disabled:checked:bg-gray-100 dark:border-white/10 dark:bg-white/5 dark:checked:border-indigo-500 dark:checked:bg-indigo-500 dark:indeterminate:border-indigo-500 dark:indeterminate:bg-indigo-500 dark:focus-visible:outline-indigo-500 forced-colors:appearance-auto"
  )

  EMAIL_CLASSES = ClassVariants.build(
    base: "block w-full rounded-md bg-white px-3 py-1.5 text-base text-gray-900 outline-1 -outline-offset-1 outline-gray-300 placeholder:text-gray-400 focus:outline-2 focus:-outline-offset-2 focus:outline-indigo-600 sm:text-sm/6 dark:bg-white/5 dark:text-white dark:outline-white/10 dark:placeholder:text-gray-500 dark:focus:outline-indigo-500"
  )

  LABEL_CLASSES = ClassVariants.build(
    base: "block text-sm/6 font-medium text-gray-900 dark:text-gray-100"
  )

  PASSWORD_CLASSES = ClassVariants.build(
    base: "block w-full rounded-md bg-white px-3 py-1.5 text-base text-gray-900 outline-1 -outline-offset-1 outline-gray-300 placeholder:text-gray-400 focus:outline-2 focus:-outline-offset-2 focus:outline-indigo-600 sm:text-sm/6 dark:bg-white/5 dark:text-white dark:outline-white/10 dark:placeholder:text-gray-500 dark:focus:outline-indigo-500"
  )

  SUBMIT_CLASSES = ClassVariants.build(
    base: "flex w-full justify-center rounded-md bg-indigo-600 px-3 py-1.5 text-sm/6 font-semibold text-white shadow-xs hover:bg-indigo-500 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600 dark:bg-indigo-500 dark:shadow-none dark:hover:bg-indigo-400 dark:focus-visible:outline-indigo-500"
  )

  def check_box(method, options = {}, checked_value = "1", unchecked_value = "0")
    super(method, options.reverse_merge(class: CHECK_BOX_CLASSES.render), checked_value, unchecked_value)
  end

  def email_field(method, options = {})
    super(method, options.reverse_merge(class: EMAIL_CLASSES.render))
  end

  def label(method, text = nil, options = {}, &)
    super(method, text, options.reverse_merge(class: LABEL_CLASSES.render), &)
  end

  def password_field(method, options = {})
    super(method, options.reverse_merge(class: PASSWORD_CLASSES.render))
  end

  def submit(value = nil, options = {})
    super(value, options.reverse_merge(class: SUBMIT_CLASSES.render))
  end
end
