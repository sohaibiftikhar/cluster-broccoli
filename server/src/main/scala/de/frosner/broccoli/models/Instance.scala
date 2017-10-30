package de.frosner.broccoli.models

import de.frosner.broccoli.RemoveSecrets
import play.api.libs.json._

import scala.util.Try

case class Instance(id: String, template: Template, parameterValues: Map[String, String]) extends Serializable

object Instance {
  implicit val instanceApiWrites: Writes[Instance] = {
    import Template.templateApiWrites
    Json.writes[Instance]
  }

  implicit val instancePersistenceWrites: Writes[Instance] = {
    import Template.templatePersistenceWrites
    Json.writes[Instance]
  }

  implicit val instancePersistenceReads: Reads[Instance] = {
    import Template.templatePersistenceReads
    Json.reads[Instance]
  }

  /**
    * Remove secrets from an instance.
    *
    * This instance removes all values of parameters marked as secrets from the instance parameters.
    */
  implicit val instanceRemoveSecrets: RemoveSecrets[Instance] = RemoveSecrets.instance { instance =>
    // FIXME "censoring" through setting the values null is ugly but using Option[String] gives me stupid Json errors
    val parameterInfos = instance.template.parameterInfos
    instance.copy(parameterValues = instance.parameterValues.map {
      case (parameter, value) =>
        val possiblyCensoredValue = if (parameterInfos.get(parameter).exists(_.secret.contains(true))) {
          null
        } else {
          value
        }
        (parameter, possiblyCensoredValue)
    })
  }

}
