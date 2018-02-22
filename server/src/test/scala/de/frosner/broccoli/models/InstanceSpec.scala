package de.frosner.broccoli.models

import de.frosner.broccoli.RemoveSecrets.ToRemoveSecretsOps
import org.specs2.ScalaCheck
import org.specs2.mutable.Specification

class InstanceSpec extends Specification with ScalaCheck with ModelArbitraries with ToRemoveSecretsOps {

  "The RemoveSecrets instance" should {
    "remove secret instance parameters" in prop { (instance: Instance) =>
      val publicInstance = instance.removeSecrets
      val (secret, public) = publicInstance.parameterValues.partition {
        case (id, _) =>
          instance.template.parameterInfos(id).secret.getOrElse(false)
      }
      (secret.values must contain(beNull[String]).foreach) and (public.values must contain(not(beNull[String])).foreach)
    }
  }

  "An instance" should {
    "be possible to construct if the parameters to be filled match the ones in the template's parameter infos" in {
      val parameterInfos = Map("id" -> ParameterInfo("id", None, None, None, None, None))
      val instance1 = Instance("1", Template("1", "\"{{id}}\"", "desc", parameterInfos), Map("id" -> "Heinz"))
      val instance2 = Instance("1", Template("1", "\"{{id}}\"", "desc", parameterInfos), Map("id" -> "Heinz"))
      instance1 === instance2
    }

    "throw an exception during construction if not all variables are specified in the template's parameter infos" in {
      Instance("1", Template("1", "\"{{id}}\"", "desc", Map.empty), Map("id" -> "Heinz")) must throwA(
        new IllegalArgumentException(
          "requirement failed: The given parameters values (Set(id)) need to match the ones in the template (Set())."))
    }
  }

}
