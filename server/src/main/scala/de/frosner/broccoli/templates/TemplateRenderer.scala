package de.frosner.broccoli.templates

import com.hubspot.jinjava.interpret.{FatalTemplateErrorsException, RenderResult}
import com.hubspot.jinjava.interpret.TemplateError.ErrorType
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

  private[templates] def sanitize(parameter: String,
                                  value: String,
                                  parameterInfos: Map[String, ParameterInfo]): String = {
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

  def renderForResult(instance: Instance): RenderResult = {
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
    jinjava.renderForResult(template.template, parameterValues)
  }

  def renderJson(instance: Instance): JsValue = {
    val renderResult = renderForResult(instance)
    val fatalErrors = renderResult.getErrors.filter(error => error.getSeverity == ErrorType.FATAL)

    if (!fatalErrors.isEmpty()) {
      throw new FatalTemplateErrorsException(instance.template.template, fatalErrors)
    }

    Json.parse(renderResult.getOutput)
  }
}
