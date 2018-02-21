package de.frosner.broccoli.templates

import de.frosner.broccoli.models.ParameterType

object TemplateConfig {

  final case class TemplateInfo(description: Option[String], parameters: Map[String, Parameter])

  final case class Parameter(name: Option[String],
                             default: Option[String],
                             secret: Option[Boolean],
                             `type`: Option[ParameterType],
                             orderIndex: Option[Int])

}
