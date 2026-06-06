module EkylibreHve
  class Engine < ::Rails::Engine
    config.after_initialize do
      ::Backend::BaseController.prepend_view_path EkylibreHve::Engine.root.join('app', 'views')
    end

    initializer :ekylibre_hve_i18n do |app|
      app.config.i18n.load_path += Dir[EkylibreHve::Engine.root.join('config', 'locales', '**', '*.yml')]
    end

    initializer :ekylibre_hve_extend_navigation do |_app|
      EkylibreHve::ExtNavigation.add_navigation_xml_to_existing_tree
    end

    initializer :ekylibre_hve_restfully_manageable do |app|
      app.config.x.restfully_manageable.view_paths << EkylibreHve::Engine.root.join('app', 'views')
    end
  end
end
