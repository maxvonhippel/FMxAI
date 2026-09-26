module

/-!
# The map's data

This is the file to edit to add an organisation or a category. Categories are an enumeration,
so an organisation can only be tagged with a category that exists, and a category that has
no colour or name does not compile.
-/

namespace Fmxai.Map

@[expose] public section

/-- The categories, one circle each. -/
inductive Category where
  /-- AI for mathematics. -/
  | mathematics
  /-- Secure program synthesis. -/
  | securePS
  /-- Legal technology. -/
  | legalTech
  /-- Accelerators and incubators. -/
  | accelerator
  /-- Model developers. -/
  | models
  /-- Academic research labs. -/
  | researchLab
  deriving DecidableEq, Repr

/-- Every category, in drawing order. -/
def Category.all : List Category :=
  [.mathematics, .securePS, .legalTech, .accelerator, .models, .researchLab]

/-- The label drawn next to the circle. -/
def Category.name : Category → String
  | .mathematics => "Mathematics"
  | .securePS => "Secure Program Synthesis"
  | .legalTech => "Legal Tech"
  | .accelerator => "Accelerator"
  | .models => "Models"
  | .researchLab => "Research Lab"

/-- The circle's colour. -/
def Category.color : Category → String
  | .mathematics => "#6366f1"
  | .securePS => "#ec4899"
  | .legalTech => "#10b981"
  | .accelerator => "#f59e0b"
  | .models => "#8b5cf6"
  | .researchLab => "#06b6d4"

/-- An organisation on the map. -/
structure Org where
  /-- Display name. -/
  name : String
  /-- Where its dot links to. -/
  url : String
  /-- Careers page, if it has one; listed next to the map. -/
  careers : Option String := none
  /-- The circles its dot must lie in. Order does not matter. -/
  categories : List Category
  deriving Repr, DecidableEq

/-- The organisations. -/
def orgs : List Org :=
  [ { name := "Axiom", url := "https://axiommath.ai/", careers := "https://axiommath.ai/join-us",
      categories := [.mathematics, .securePS, .models] },
    { name := "Harmonic", url := "https://harmonic.fun/", categories := [.mathematics, .models] },
    { name := "Logical Intelligence", url := "https://logicalintelligence.com/",
      categories := [.mathematics, .models] },
    { name := "Principia Labs", url := "https://www.principialabs.org/",
      categories := [.mathematics] },
    { name := "Theorem", url := "https://theorem.dev/", careers := "https://theorem.dev/careers/",
      categories := [.securePS] },
    { name := "Sigil Logic", url := "https://sigillogic.com/",
      careers := "https://sigillogic.com/careers", categories := [.securePS] },
    { name := "Higher Order Co", url := "https://higherorderco.com/", categories := [.securePS] },
    { name := "NDEA", url := "https://ndea.com/", careers := "https://ndea.com/join",
      categories := [.securePS, .models] },
    { name := "Benchify", url := "https://benchify.com/", categories := [.legalTech] },
    { name := "AI Safety Founders", url := "https://aisfounders.com/",
      categories := [.accelerator] },
    { name := "Seldon Lab", url := "https://seldonlab.com/", categories := [.accelerator] },
    { name := "FMAI Lab", url := "https://fmailab.doc.ic.ac.uk/", categories := [.researchLab] },
    { name := "Formal Computing and AI Lab", url := "https://sites.google.com/view/fcai-lab",
      careers := "https://sites.google.com/view/fcai-lab", categories := [.researchLab] },
    { name := "ForMACE Lab", url := "https://formace-lab.gitlab.io/webpage/",
      careers := "https://formace-lab.gitlab.io/webpage/posts/recruiting/",
      categories := [.researchLab] },
    { name := "Reasonable", url := "https://reasonable.io/",
      careers := "https://apply.workable.com/reasonable", categories := [.securePS, .models] },
    { name := "Horizon Omega", url := "https://www.horizonomega.org/",
      categories := [.researchLab] } ]

/-- Whether an organisation is in a category. -/
def Org.inCat (o : Org) (c : Category) : Bool := o.categories.contains c

/-- Whether some organisation is in both categories, i.e. whether the circles must overlap. -/
def Category.shares (os : List Org) (a b : Category) : Bool :=
  os.any fun o => o.inCat a && o.inCat b

end

/-- `Category.all` is complete. -/
public theorem Category.mem_all (c : Category) : c ∈ Category.all := by
  cases c <;> decide

end Fmxai.Map
