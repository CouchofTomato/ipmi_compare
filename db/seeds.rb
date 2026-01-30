if Rails.env.production?
  raise "Seeding in production is disabled."
end

# Clear data in dependency-safe order.
ActiveRecord::Base.connection.execute("DELETE FROM coverage_categories_plan_modules")
CostShareLink.delete_all
CostShare.delete_all
ModuleBenefit.delete_all
BenefitLimitGroup.delete_all
PlanModuleRequirement.delete_all
PlanGeographicCoverArea.delete_all
PlanResidencyEligibility.delete_all
PlanModule.delete_all
ModuleGroup.delete_all
PlanVersion.delete_all
Plan.delete_all
Benefit.delete_all
CoverageCategory.delete_all
GeographicCoverArea.delete_all
Insurer.delete_all
WizardProgress.delete_all
User.delete_all

User.create!(email: "admin@example.com", password: "password", admin: true)

def create_cost_share!(scope:, cost_share_type:, amount:, unit:, per:, currency: nil, notes: nil)
  CostShare.create!(
    scope: scope,
    cost_share_type: cost_share_type,
    amount: amount,
    unit: unit,
    per: per,
    currency: currency,
    notes: notes
  )
end

coverage_categories =
  [
    [ "Hospital & Inpatient", 1 ],
    [ "Outpatient & Primary Care", 2 ],
    [ "Maternity", 3 ],
    [ "Dental", 4 ],
    [ "Vision", 5 ],
    [ "Emergency & Evacuation", 6 ],
    [ "Wellness", 7 ]
  ].map do |name, position|
    CoverageCategory.create!(name: name, position: position)
  end

benefits = {
  inpatient: Benefit.create!(name: "Inpatient hospital stay", coverage_category: coverage_categories[0]),
  surgery: Benefit.create!(name: "Surgical procedures", coverage_category: coverage_categories[0]),
  icu: Benefit.create!(name: "Intensive care unit", coverage_category: coverage_categories[0]),
  specialist_inpatient: Benefit.create!(name: "Inpatient specialist fees", coverage_category: coverage_categories[0]),
  inpatient_rehab: Benefit.create!(name: "Inpatient rehabilitation", coverage_category: coverage_categories[0]),
  inpatient_pharmacy: Benefit.create!(name: "Inpatient pharmacy", coverage_category: coverage_categories[0]),
  inpatient_diagnostics: Benefit.create!(name: "Inpatient diagnostics", coverage_category: coverage_categories[0]),
  inpatient_room_upgrade: Benefit.create!(name: "Room upgrade allowance", coverage_category: coverage_categories[0]),
  outpatient: Benefit.create!(name: "Outpatient visits", coverage_category: coverage_categories[1]),
  primary_care: Benefit.create!(name: "Primary care", coverage_category: coverage_categories[1]),
  specialist_visit: Benefit.create!(name: "Specialist consultation", coverage_category: coverage_categories[1]),
  imaging: Benefit.create!(name: "Diagnostic imaging (MRI/CT/X-ray)", coverage_category: coverage_categories[1]),
  outpatient_lab: Benefit.create!(name: "Outpatient lab work", coverage_category: coverage_categories[1]),
  outpatient_therapy: Benefit.create!(name: "Physical therapy", coverage_category: coverage_categories[1]),
  outpatient_mental_health: Benefit.create!(name: "Outpatient mental health", coverage_category: coverage_categories[1]),
  outpatient_prescriptions: Benefit.create!(name: "Outpatient prescription drugs", coverage_category: coverage_categories[1]),
  maternity: Benefit.create!(name: "Maternity care", coverage_category: coverage_categories[2]),
  prenatal: Benefit.create!(name: "Prenatal care", coverage_category: coverage_categories[2]),
  newborn: Benefit.create!(name: "Newborn care", coverage_category: coverage_categories[2]),
  fertility: Benefit.create!(name: "Fertility treatment", coverage_category: coverage_categories[2]),
  complication: Benefit.create!(name: "Pregnancy complications", coverage_category: coverage_categories[2]),
  midwife: Benefit.create!(name: "Midwife services", coverage_category: coverage_categories[2]),
  lactation: Benefit.create!(name: "Lactation support", coverage_category: coverage_categories[2]),
  dental_basic: Benefit.create!(name: "Dental - basic", coverage_category: coverage_categories[3]),
  dental_major: Benefit.create!(name: "Dental - major", coverage_category: coverage_categories[3]),
  dental_ortho: Benefit.create!(name: "Dental - orthodontics", coverage_category: coverage_categories[3]),
  dental_periodontal: Benefit.create!(name: "Dental - periodontal care", coverage_category: coverage_categories[3]),
  dental_implants: Benefit.create!(name: "Dental - implants", coverage_category: coverage_categories[3]),
  dental_endodontics: Benefit.create!(name: "Dental - endodontics", coverage_category: coverage_categories[3]),
  dental_prosthodontics: Benefit.create!(name: "Dental - prosthodontics", coverage_category: coverage_categories[3]),
  vision_exam: Benefit.create!(name: "Vision exam", coverage_category: coverage_categories[4]),
  vision_lenses: Benefit.create!(name: "Vision lenses and frames", coverage_category: coverage_categories[4]),
  vision_surgery: Benefit.create!(name: "Vision correction surgery", coverage_category: coverage_categories[4]),
  vision_contact_lenses: Benefit.create!(name: "Contact lenses allowance", coverage_category: coverage_categories[4]),
  vision_glaucoma: Benefit.create!(name: "Glaucoma screening", coverage_category: coverage_categories[4]),
  vision_retinal: Benefit.create!(name: "Retinal screening", coverage_category: coverage_categories[4]),
  vision_pediatric: Benefit.create!(name: "Pediatric vision care", coverage_category: coverage_categories[4]),
  emergency: Benefit.create!(name: "Emergency care", coverage_category: coverage_categories[5]),
  ambulance: Benefit.create!(name: "Ambulance services", coverage_category: coverage_categories[5]),
  evacuation: Benefit.create!(name: "Medical evacuation", coverage_category: coverage_categories[5]),
  repatriation: Benefit.create!(name: "Repatriation of remains", coverage_category: coverage_categories[5]),
  emergency_room: Benefit.create!(name: "Emergency room visit", coverage_category: coverage_categories[5]),
  urgent_care: Benefit.create!(name: "Urgent care visit", coverage_category: coverage_categories[5]),
  air_ambulance: Benefit.create!(name: "Air ambulance", coverage_category: coverage_categories[5]),
  crisis_transport: Benefit.create!(name: "Medical transport coordination", coverage_category: coverage_categories[5]),
  wellness: Benefit.create!(name: "Wellness checkups", coverage_category: coverage_categories[6]),
  immunizations: Benefit.create!(name: "Routine immunizations", coverage_category: coverage_categories[6]),
  screenings: Benefit.create!(name: "Preventive screenings", coverage_category: coverage_categories[6]),
  health_coaching: Benefit.create!(name: "Health coaching", coverage_category: coverage_categories[6]),
  nutrition: Benefit.create!(name: "Nutrition counseling", coverage_category: coverage_categories[6]),
  smoking_cessation: Benefit.create!(name: "Smoking cessation program", coverage_category: coverage_categories[6]),
  fitness: Benefit.create!(name: "Fitness program reimbursement", coverage_category: coverage_categories[6])
}

geo_areas = {
  worldwide: GeographicCoverArea.create!(name: "Worldwide", code: "WW"),
  worldwide_ex_us: GeographicCoverArea.create!(name: "Worldwide (excluding USA)", code: "WW-EX-US"),
  europe: GeographicCoverArea.create!(name: "Europe", code: "EU")
}

insurers = {
  atlas: Insurer.create!(name: "Atlas International", jurisdiction: "US"),
  nova: Insurer.create!(name: "Nova Global", jurisdiction: "GB")
}

def build_plan!(insurer:, name:, version_year:, policy_type:, cover_area_codes:, residency_countries:)
  plan = Plan.create!(
    insurer: insurer,
    name: name,
    version_year: version_year,
    effective_on: Date.new(version_year, 1, 1),
    effective_through: nil,
    children_only_allowed: false,
    min_age: 0,
    max_age: 75,
    policy_type: policy_type,
    published: true,
    last_reviewed_at: Date.new(version_year, 1, 10),
    next_review_due: Date.new(version_year, 12, 1),
    review_notes: "Initial release"
  )

  plan_version = plan.current_plan_version
  PlanGeographicCoverArea.create!(
    plan_version: plan_version,
    geographic_cover_area: GeographicCoverArea.find_by!(code: cover_area_codes)
  )

  residency_countries.each do |country_code|
    PlanResidencyEligibility.create!(plan_version: plan_version, country_code: country_code)
  end

  plan
end

plans = {
  atlas_global: build_plan!(
    insurer: insurers[:atlas],
    name: "Atlas Global Premier",
    version_year: 2026,
    policy_type: :individual,
    cover_area_codes: "WW",
    residency_countries: %w[US CA GB]
  ),
  atlas_select: build_plan!(
    insurer: insurers[:atlas],
    name: "Atlas Select",
    version_year: 2026,
    policy_type: :company,
    cover_area_codes: "WW-EX-US",
    residency_countries: %w[AE SG HK]
  ),
  nova_europe: build_plan!(
    insurer: insurers[:nova],
    name: "Nova Europe Choice",
    version_year: 2026,
    policy_type: :corporate,
    cover_area_codes: "EU",
    residency_countries: %w[DE FR NL ES]
  )
}

plans.each_value do |plan|
  plan_version = plan.current_plan_version

  create_cost_share!(
    scope: plan_version,
    cost_share_type: :deductible,
    amount: 500,
    unit: :amount,
    per: :per_year,
    currency: "USD",
    notes: "Annual plan-level deductible"
  )
end

def build_modules_for_plan!(plan:, benefits:, coverage_categories:)
  plan_version = plan.current_plan_version

  inpatient_group = ModuleGroup.create!(plan_version: plan_version, name: "Inpatient", position: 1)
  outpatient_group = ModuleGroup.create!(plan_version: plan_version, name: "Outpatient", position: 2)
  emergency_group = ModuleGroup.create!(plan_version: plan_version, name: "Emergency & Evacuation", position: 3)
  maternity_group = ModuleGroup.create!(plan_version: plan_version, name: "Maternity", position: 4)
  dental_group = ModuleGroup.create!(plan_version: plan_version, name: "Dental", position: 5)
  vision_group = ModuleGroup.create!(plan_version: plan_version, name: "Vision", position: 6)

  inpatient_module = PlanModule.create!(
    plan_version: plan_version,
    module_group: inpatient_group,
    name: "Inpatient & Surgery",
    is_core: true,
    overall_limit_usd: 2_000_000,
    overall_limit_unit: "per_policy_year",
    overall_limit_notes: "Shared across inpatient and surgery"
  )

  outpatient_module = PlanModule.create!(
    plan_version: plan_version,
    module_group: outpatient_group,
    name: "Outpatient & Primary Care",
    is_core: true,
    overall_limit_usd: 50_000,
    overall_limit_unit: "per_policy_year"
  )

  emergency_module = PlanModule.create!(
    plan_version: plan_version,
    module_group: emergency_group,
    name: "Emergency & Evacuation",
    is_core: true,
    overall_limit_usd: 250_000,
    overall_limit_unit: "per_policy_year"
  )

  maternity_module = PlanModule.create!(
    plan_version: plan_version,
    module_group: maternity_group,
    name: "Maternity",
    is_core: false,
    overall_limit_usd: 20_000,
    overall_limit_unit: "per_policy_year"
  )

  dental_module = PlanModule.create!(
    plan_version: plan_version,
    module_group: dental_group,
    name: "Dental",
    is_core: false,
    overall_limit_usd: 2_500,
    overall_limit_unit: "per_policy_year"
  )

  vision_module = PlanModule.create!(
    plan_version: plan_version,
    module_group: vision_group,
    name: "Vision",
    is_core: false,
    overall_limit_usd: 500,
    overall_limit_unit: "per_policy_year"
  )

  inpatient_module.coverage_categories << coverage_categories[0]
  outpatient_module.coverage_categories << coverage_categories[1]
  emergency_module.coverage_categories << coverage_categories[5]
  maternity_module.coverage_categories << coverage_categories[2]
  dental_module.coverage_categories << coverage_categories[3]
  vision_module.coverage_categories << coverage_categories[4]

  inpatient_limit_group = BenefitLimitGroup.create!(
    plan_module: inpatient_module,
    name: "Inpatient annual limit",
    limit_unit: "per_policy_year",
    limit_usd: 1_000_000
  )

  ModuleBenefit.create!(
    plan_module: inpatient_module,
    benefit: benefits[:inpatient],
    benefit_limit_group: inpatient_limit_group,
    coverage_description: "Semi-private room, medically necessary stay"
  )

  ModuleBenefit.create!(
    plan_module: inpatient_module,
    benefit: benefits[:surgery],
    coverage_description: "Medically necessary surgery, surgeon and anesthesia"
  )

  ModuleBenefit.create!(
    plan_module: inpatient_module,
    benefit: benefits[:icu],
    coverage_description: "ICU stay when medically necessary"
  )

  ModuleBenefit.create!(
    plan_module: inpatient_module,
    benefit: benefits[:specialist_inpatient],
    coverage_description: "Inpatient specialist fees and rounds"
  )

  ModuleBenefit.create!(
    plan_module: inpatient_module,
    benefit: benefits[:inpatient_rehab],
    coverage_description: "Post-acute inpatient rehabilitation"
  )

  ModuleBenefit.create!(
    plan_module: inpatient_module,
    benefit: benefits[:inpatient_pharmacy],
    coverage_description: "Medications during inpatient stay"
  )

  ModuleBenefit.create!(
    plan_module: inpatient_module,
    benefit: benefits[:inpatient_diagnostics],
    coverage_description: "Imaging and lab tests during admission"
  )

  ModuleBenefit.create!(
    plan_module: inpatient_module,
    benefit: benefits[:inpatient_room_upgrade],
    coverage_description: "Room upgrade subject to medical necessity"
  )

  ModuleBenefit.create!(
    plan_module: outpatient_module,
    benefit: benefits[:outpatient],
    coverage_description: "Specialist and outpatient visits",
    waiting_period_months: 0
  )

  ModuleBenefit.create!(
    plan_module: outpatient_module,
    benefit: benefits[:primary_care],
    coverage_description: "General practitioner visits",
    waiting_period_months: 0
  )

  ModuleBenefit.create!(
    plan_module: outpatient_module,
    benefit: benefits[:specialist_visit],
    coverage_description: "Specialist consultations and follow-ups",
    waiting_period_months: 0
  )

  ModuleBenefit.create!(
    plan_module: outpatient_module,
    benefit: benefits[:imaging],
    coverage_description: "Imaging diagnostics when medically necessary",
    waiting_period_months: 0
  )

  ModuleBenefit.create!(
    plan_module: outpatient_module,
    benefit: benefits[:outpatient_lab],
    coverage_description: "Routine and diagnostic lab work",
    waiting_period_months: 0
  )

  ModuleBenefit.create!(
    plan_module: outpatient_module,
    benefit: benefits[:outpatient_therapy],
    coverage_description: "Physical and occupational therapy sessions",
    waiting_period_months: 0
  )

  ModuleBenefit.create!(
    plan_module: outpatient_module,
    benefit: benefits[:outpatient_mental_health],
    coverage_description: "Outpatient counseling and therapy",
    waiting_period_months: 0
  )

  ModuleBenefit.create!(
    plan_module: outpatient_module,
    benefit: benefits[:outpatient_prescriptions],
    coverage_description: "Outpatient prescription medications",
    waiting_period_months: 0
  )

  ModuleBenefit.create!(
    plan_module: emergency_module,
    benefit: benefits[:emergency],
    coverage_description: "Emergency room stabilization and treatment"
  )

  ModuleBenefit.create!(
    plan_module: emergency_module,
    benefit: benefits[:ambulance],
    coverage_description: "Ground ambulance to nearest appropriate facility"
  )

  ModuleBenefit.create!(
    plan_module: emergency_module,
    benefit: benefits[:evacuation],
    coverage_description: "Medically necessary evacuation and repatriation"
  )

  ModuleBenefit.create!(
    plan_module: emergency_module,
    benefit: benefits[:repatriation],
    coverage_description: "Repatriation of remains in case of death"
  )

  ModuleBenefit.create!(
    plan_module: emergency_module,
    benefit: benefits[:emergency_room],
    coverage_description: "Emergency room facility charges"
  )

  ModuleBenefit.create!(
    plan_module: emergency_module,
    benefit: benefits[:urgent_care],
    coverage_description: "Urgent care center visits"
  )

  ModuleBenefit.create!(
    plan_module: emergency_module,
    benefit: benefits[:air_ambulance],
    coverage_description: "Air ambulance when medically necessary"
  )

  ModuleBenefit.create!(
    plan_module: emergency_module,
    benefit: benefits[:crisis_transport],
    coverage_description: "Transport coordination during emergencies"
  )

  ModuleBenefit.create!(
    plan_module: maternity_module,
    benefit: benefits[:maternity],
    coverage_description: "Prenatal, delivery, and postnatal care",
    waiting_period_months: 10
  )

  ModuleBenefit.create!(
    plan_module: maternity_module,
    benefit: benefits[:prenatal],
    coverage_description: "Routine prenatal visits and diagnostics",
    waiting_period_months: 10
  )

  ModuleBenefit.create!(
    plan_module: maternity_module,
    benefit: benefits[:newborn],
    coverage_description: "Newborn care immediately after delivery",
    waiting_period_months: 10
  )

  ModuleBenefit.create!(
    plan_module: maternity_module,
    benefit: benefits[:fertility],
    coverage_description: "Fertility evaluation and treatment",
    waiting_period_months: 12
  )

  ModuleBenefit.create!(
    plan_module: maternity_module,
    benefit: benefits[:complication],
    coverage_description: "Pregnancy complication management",
    waiting_period_months: 10
  )

  ModuleBenefit.create!(
    plan_module: maternity_module,
    benefit: benefits[:midwife],
    coverage_description: "Certified midwife services",
    waiting_period_months: 10
  )

  ModuleBenefit.create!(
    plan_module: maternity_module,
    benefit: benefits[:lactation],
    coverage_description: "Lactation support services",
    waiting_period_months: 10
  )

  ModuleBenefit.create!(
    plan_module: dental_module,
    benefit: benefits[:dental_basic],
    coverage_description: "Preventive and basic dental services"
  )

  ModuleBenefit.create!(
    plan_module: dental_module,
    benefit: benefits[:dental_major],
    coverage_description: "Major dental services, crowns, and bridges"
  )

  ModuleBenefit.create!(
    plan_module: dental_module,
    benefit: benefits[:dental_ortho],
    coverage_description: "Orthodontic services with annual limit"
  )

  ModuleBenefit.create!(
    plan_module: dental_module,
    benefit: benefits[:dental_periodontal],
    coverage_description: "Periodontal treatments and deep cleaning"
  )

  ModuleBenefit.create!(
    plan_module: dental_module,
    benefit: benefits[:dental_implants],
    coverage_description: "Dental implant services subject to limits"
  )

  ModuleBenefit.create!(
    plan_module: dental_module,
    benefit: benefits[:dental_endodontics],
    coverage_description: "Root canal and endodontic services"
  )

  ModuleBenefit.create!(
    plan_module: dental_module,
    benefit: benefits[:dental_prosthodontics],
    coverage_description: "Crowns, bridges, dentures, and prosthodontics"
  )

  ModuleBenefit.create!(
    plan_module: vision_module,
    benefit: benefits[:vision_exam],
    coverage_description: "Annual routine eye exam"
  )

  ModuleBenefit.create!(
    plan_module: vision_module,
    benefit: benefits[:vision_lenses],
    coverage_description: "Frames or contact lenses allowance"
  )

  ModuleBenefit.create!(
    plan_module: vision_module,
    benefit: benefits[:vision_surgery],
    coverage_description: "Laser vision correction when eligible"
  )

  ModuleBenefit.create!(
    plan_module: vision_module,
    benefit: benefits[:vision_contact_lenses],
    coverage_description: "Contact lens allowance"
  )

  ModuleBenefit.create!(
    plan_module: vision_module,
    benefit: benefits[:vision_glaucoma],
    coverage_description: "Glaucoma screening as recommended"
  )

  ModuleBenefit.create!(
    plan_module: vision_module,
    benefit: benefits[:vision_retinal],
    coverage_description: "Retinal screening for high-risk members"
  )

  ModuleBenefit.create!(
    plan_module: vision_module,
    benefit: benefits[:vision_pediatric],
    coverage_description: "Pediatric eye care and screenings"
  )

  ModuleBenefit.create!(
    plan_module: outpatient_module,
    benefit: benefits[:wellness],
    coverage_description: "Annual wellness exams and screenings"
  )

  ModuleBenefit.create!(
    plan_module: outpatient_module,
    benefit: benefits[:immunizations],
    coverage_description: "Age-appropriate immunizations"
  )

  ModuleBenefit.create!(
    plan_module: outpatient_module,
    benefit: benefits[:screenings],
    coverage_description: "Preventive screenings per guidelines"
  )

  ModuleBenefit.create!(
    plan_module: outpatient_module,
    benefit: benefits[:health_coaching],
    coverage_description: "Lifestyle and chronic condition coaching"
  )

  ModuleBenefit.create!(
    plan_module: outpatient_module,
    benefit: benefits[:nutrition],
    coverage_description: "Nutrition counseling and diet planning"
  )

  ModuleBenefit.create!(
    plan_module: outpatient_module,
    benefit: benefits[:smoking_cessation],
    coverage_description: "Smoking cessation programs and support"
  )

  ModuleBenefit.create!(
    plan_module: outpatient_module,
    benefit: benefits[:fitness],
    coverage_description: "Fitness and wellness reimbursement"
  )

  PlanModuleRequirement.create!(
    plan_version: plan_version,
    dependent_module: maternity_module,
    required_module: inpatient_module
  )

  PlanModuleRequirement.create!(
    plan_version: plan_version,
    dependent_module: dental_module,
    required_module: outpatient_module
  )

  create_cost_share!(
    scope: inpatient_module,
    cost_share_type: :deductible,
    amount: 250,
    unit: :amount,
    per: :per_visit,
    currency: "USD",
    notes: "Inpatient admission deductible"
  )

  outpatient_copay = create_cost_share!(
    scope: outpatient_module,
    cost_share_type: :coinsurance,
    amount: 20,
    unit: :percent,
    per: :per_visit,
    notes: "Coinsurance for outpatient services"
  )

  maternity_copay = create_cost_share!(
    scope: maternity_module,
    cost_share_type: :coinsurance,
    amount: 10,
    unit: :percent,
    per: :per_visit
  )

  CostShareLink.create!(
    cost_share: maternity_copay,
    linked_cost_share: outpatient_copay,
    relationship_type: :dependent
  )
end

plans.each_value do |plan|
  build_modules_for_plan!(plan: plan, benefits: benefits, coverage_categories: coverage_categories)
end
