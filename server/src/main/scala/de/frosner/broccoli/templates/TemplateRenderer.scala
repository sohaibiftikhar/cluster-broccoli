package de.frosner.broccoli.templates

import com.hubspot.jinjava.{Jinjava, JinjavaConfig}
import de.frosner.broccoli.models.{Instance, ParameterInfo, ParameterType}
import org.apache.commons.lang3.StringEscapeUtils
import play.api.libs.json.{JsValue, Json}

import scala.collection.JavaConversions._

/**
  * Renders json representation of the passed instance
  *
  * @param defaultType The default type of template parameters
  * @param jinjavaConfig Jinjava configuration
  */
class TemplateRenderer(defaultType: ParameterType, jinjavaConfig: JinjavaConfig) {
  val jinjava = new Jinjava(jinjavaConfig)

  def sanitize(parameter: String, value: String, parameterInfos: Map[String, ParameterInfo]): String = {
    val parameterType = parameterInfos
      .get(parameter)
      .flatMap(_.`type`)
      .getOrElse(defaultType)
    val sanitized = parameterType match {
      case ParameterType.Raw => value
      case ParameterType.String =>
        StringEscapeUtils.escapeJson(value)
    }
    sanitized
  }

  def renderJson(instance: Instance): JsValue = {
    val template = instance.template
    val parameterInfos = template.parameterInfos
    val parameterDefaults = parameterInfos
      .map {
        case (name, parameterInfo) => (name, parameterInfo.default)
      }
      .collect {
        case (name, Some(value)) => (name, value)
      }
    val parameterValues = (parameterDefaults ++ instance.parameterValues).map {
      case (name, value) => (name, sanitize(name, value, parameterInfos))
    }
    Json.parse(jinjava.render(template.template, parameterValues))
  }
}
