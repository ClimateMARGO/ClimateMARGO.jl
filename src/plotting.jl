rcParams = PyPlot.PyDict(PyPlot.matplotlib."rcParams")
rcParams["lines.linewidth"] = 3 # Change linewidth

function add_label(s; xy=(0, 1.03), fontsize=12)
    annotate(s=s,xy=xy,xycoords="axes fraction",fontsize=fontsize)
    return
end

function fill_past(model, ylims)
    domain_idx = (model.domain .> model.present_year)
    fill_between(
        model.domain[.~domain_idx],
        ones(size(model.domain[.~domain_idx])) * ylims[1] * 2.,
        ones(size(model.domain[.~domain_idx])) * ylims[2] * 2.,
        facecolor="b", alpha=0.1
    )
    ylim(ylims)
    return
end

function plot_emissions(model::ClimateModel)
    title("effective emissions")
    plot(model.domain, zeros(size(model.domain)), "k--", alpha=0.5)
    plot(model.domain, effective_baseline_emissions(model), color="C0", label=L"$rq$ (no-policy baseline)")
    plot(model.domain, effective_emissions(model), color="C1", label=L"$rq(1-M) - q_{0}R$ (controlled)")
    ylimit = maximum(effective_baseline_emissions(model)) * 1.1
    ylims = [-ylimit, ylimit]
    ylabel(L"effective CO$_{2e}$ emissions [ppm / yr]")
    xlim(model.domain[1],2200.)
    xticks(model.domain[1]:40.:2200.)
    xlabel("year")
    fill_past(model, ylims)
    grid(true)
    return
end

function plot_concentrations(model::ClimateModel)
    title("concentrations")
    plot(model.domain, CO₂_baseline(model), color="C0", label=L"$c$ (no-policy baseline)")
    plot(model.domain, CO₂(model), color="C1", label=L"$c_{M,R}$ (controlled)")
    ylims = [0., maximum(CO₂_baseline(model))*1.05]
    fill_past(model, ylims)
    ylabel(L"CO$_{2e}$ concentration [ppm]")
    xlabel("year")
    xlim(model.domain[1],2200.)
    xticks(model.domain[1]:40.:2200.)
    grid(true)
    return
end

function plot_temperatures(model::ClimateModel; hide_baseline=false)
    title("temperature change since 1850")
    plot(model.domain,2.0.*ones(size(model.domain)),"k--", alpha=0.5)
    if ~hide_baseline; plot(model.domain,δT_baseline(model), color="C0", label=L"$T$ (no-policy baseline)"); end
    plot(model.domain,δT_no_geoeng(model), color="C1", label=L"$T_{M,R}$ (controlled with $G=0$)")
    plot(model.domain,δT(model), color="C3", label=L"$T_{M,R,G}$ (controlled)")
    plot(model.domain,δT(model).*sqrt.(1. .- model.controls.adapt), color="C2", label=L"$T_{M,R,G,A}$ (adapted)")
    ylims = [0., maximum(δT_baseline(model)) * 1.05]
    fill_past(model, ylims)
    ylabel(L"temperature anomaly [$^{\circ}$C]")
    xlabel("year")
    xlim(model.domain[1],2200.)
    xticks(model.domain[1]:40.:2200.)
    grid(true)
    return
end
    
function plot_controls(model::ClimateModel)
    title("optimized control deployments")
    plot(model.domain, model.controls.mitigate, color="C0", label=L"$M$ (emissions mitigation)")
    plot(model.domain, model.controls.remove, color="C1", label=L"$R$ (carbon dioxide removal)")
    plot(model.domain, model.controls.adapt, color="C2", label=L"$A$ (adaptation)")
    plot(model.domain, model.controls.geoeng, color="C3", label=L"$G$ (solar geoengineering)")
    ylims = [0., 1.]
    fill_past(model, ylims)
    ylabel("fractional control deployment")
    xlabel("year")
    xlim(model.domain[1],2200.)
    xticks(model.domain[1]:40.:2200.)
    grid(true)
    return
end

function plot_benefits(model::ClimateModel; discounted=true)
    discount = discounting(model)
    if ~discounted; discount=1.; end;
    
    domain_idx = (model.domain .> model.present_year)
    benefits = (damage_cost_baseline(model) - damage_cost(model))
    fill_between(
        model.domain[domain_idx],
        0 .*ones(size(model.domain))[domain_idx],
        ((benefits - control_cost(model)) .* discount)[domain_idx],
        facecolor="grey", alpha=0.2
    )
    plot(model.domain[domain_idx], 0 .*ones(size(model.domain))[domain_idx], "C0--", alpha=0.5, label="no-policy baseline")
    plot(model.domain[domain_idx], (benefits .* discount)[domain_idx], color="C1", label="benefits (of avoided damages)")
    plot(model.domain[domain_idx], (- control_cost(model) .* discount)[domain_idx], color="C3", label=L"$-$ costs (of climate controls)")
    plot(model.domain[domain_idx], ((benefits - control_cost(model)) .* discount)[domain_idx], color="k", label="net benefits (benefits - costs)")
    ylabel(L"costs and benefits [10$^{12}$ \$ / year]")
    xlabel("year")
    xlim(model.domain[1],2200.)
    xticks(model.domain[1]:40.:2200.)
    grid(true)
    title("cost-benefit analysis")
    return
end
        
function plot_damages(model::ClimateModel; discounted=false, normalized=false)
    discount = deepcopy(discounting(model))
    if ~discounted; discount=1.; end;
    E = deepcopy(model.economics.GWP)/100.
    if ~normalized; E=1.; end;
    
    domain_idx = (model.domain .> model.present_year)
    fill_between(
        model.domain[domain_idx],
        0 .*ones(size(model.domain))[domain_idx],
        (control_cost(model) .* discount ./ E)[domain_idx], facecolor="C3", alpha=0.2
    )
    plot(
        model.domain[domain_idx],
        (model.economics.β .* (model.economics.GWP ./ E) .* (2.0^2).*ones(size(model.domain)))[domain_idx],
        "k--", alpha=0.5, label=L"damage threshold at 2$^{\circ}$ C with $A=0$"
    )
    plot(model.domain[domain_idx], (damage_cost_baseline(model) .* discount ./ E)[domain_idx], color="C0", label="uncontrolled damages")
    plot(model.domain[domain_idx], (net_cost(model) .* discount ./ E)[domain_idx], color="k", label="net costs (controlled damages + controls)")
    plot(model.domain[domain_idx], (damage_cost(model) .* discount ./ E)[domain_idx], color="C1", label="controlled damages")
    plot(model.domain[domain_idx], (control_cost(model) .* discount ./ E)[domain_idx], color="C3", label="cost of controls")
    ylabel(L"discounted costs [10$^{12}$ \$ / year]")
    xlabel("year")
    xlim(model.domain[1],2200.)
    xticks(model.domain[1]:40.:2200.)
    ylim([0., maximum((damage_cost_baseline(model) .* discount ./ E)[domain_idx]) * 1.25])
    grid(true)
    title("costs of avoiding a damage threshold")
    return
end
        
function plot_state(model::ClimateModel; new_figure=true, plot_legends=true)
    if new_figure
        figure(figsize=(14,8))
    end
    
    
    subplot(2,3,1)
    plot_emissions(model)
    add_label("a)")
    subplot(2,3,2)
    plot_concentrations(model)
    add_label("b)")
    subplot(2,3,3)
    plot_temperatures(model)
    add_label("c)")
    
    subplot(2,3,4)
    plot_controls(model)
    add_label("d)")
    subplot(2,3,5)
    plot_benefits(model)
    add_label("e)")
    subplot(2,3,6)
    plot_damages(model)
    add_label("f)")
    
    if plot_legends;
        for ii in 1:6
            subplot(2,3,ii);
            if ii <= 3;
                legend(loc="lower left");
            else
                legend(loc="upper left");
            end
        end
    end
    tight_layout()

    return
end

function plot_ensemble_diagnostic(ensemble::Dict{String, ClimateModel}, symbols::Array{Symbol,1}, domain::Array{Float64,1}, color = "C0", label = nothing)
    first, median, ninth = ensemble_state_statistics(ensemble, symbols, domain)
    fill_between(domain, first, ninth, facecolor=color, alpha=0.4)
    plot(domain, median, "-", color=color, alpha=1.0, label=label)
    return
end

function plot_ensemble_statistics(ensemble::Dict{String, ClimateModel}, diagnostic::Function, domain::Array{Float64,1}, color::String, label)
    first, median, ninth = ensemble_diagnostic_statistics(ensemble, diagnostic, domain)
    fill_between(domain, first, ninth, facecolor=color, alpha=0.3)
    plot(domain, median, "-", color=color, alpha=1.0, label=label)
    return
end

function plot_ensemble(ensemble::Dict{String, ClimateModel})
    (model, _) = iterate(values(ensemble))
    domain = model.domain
    
    figure(figsize=(14,8))
    
    subplot(2,3,1)
    title("emissions scenarios")
    plot(model.domain, model.economics.baseline_emissions, label="no-policy baseline")
    plot(model.domain, effective_emissions(model), label="controlled")
    if model.present_year != model.domain[1]
        plot(
            [model.present_year, model.present_year],
            [-maximum(model.economics.baseline_emissions) * 1.1, maximum(model.economics.baseline_emissions) * 1.1],
            "r--"
        )
    end
    plot(model.domain, zeros(size(model.domain)), "k--", alpha=0.5)
    ylabel(L"CO₂ emissions $q$ [ppm / yr]")
    xlim(model.domain[1],model.domain[end])
    ylim(-maximum(model.economics.baseline_emissions) * 1.1, maximum(model.economics.baseline_emissions) * 1.1)
    xlabel("year")
    grid(true)
    legend()
    annotate(s="a)",xy=(0,1.02),xycoords="axes fraction",fontsize=12)
    
    subplot(2,3,2)
    title("concentrations scenarios")
    plot(model.domain, CO₂_baseline(model), label=L"$c_{0}(t)$ (no-policy baseline)")
    plot(model.domain, CO₂(model), label=L"$c_{\phi,\varphi}(t)$ (controlled)")
    if model.present_year != model.domain[1]
        plot([model.present_year, model.present_year], [0., maximum(CO₂_baseline(model))*1.05], "r--")
    end
    legend()
    ylabel(L"CO₂ concentration $c$ [ppm]")
    xlabel("year")
    xlim(model.domain[1],model.domain[end])
    ylim([0., maximum(CO₂_baseline(model))*1.05])
    grid(true)
    annotate(s="b)",xy=(0,1.02),xycoords="axes fraction",fontsize=12)
    
    subplot(2,3,3)
    title("optimized control deployments")
    plot(model.domain, model.controls.remove, label=L"$\phi$ (negative emissions)")
    plot(model.domain, model.controls.mitigate, label=L"$\varphi$ (emissions reductions)")
    plot(model.domain, model.controls.adapt, label=L"$\chi$ (adaptation)")
    plot(model.domain, model.controls.geoeng, label=L"$\lambda$ (geoengineering)")
    if model.present_year != model.domain[1]
        plot([model.present_year, model.present_year], [0., 1.], "r--")
    end
    ylabel(L"fractional control deployment $\alpha$")
    xlabel("year")
    xlim(model.domain[1],model.domain[end])
    ylim([0,1])
    grid(true)
    legend()
    annotate(s="c)",xy=(0,1.02),xycoords="axes fraction",fontsize=12)
    
    subplot(2,3,4)
    title("costs of deploying climate controls")
    plot(model.domain, f(model.controls.remove) * model.economics.remove_cost, label=L"$C_{\phi} f(\phi)$ (negative emissions)")
    plot(model.domain, f(model.controls.mitigate) * model.economics.mitigate_cost, label=L"$C_{\varphi} f(\varphi)$ (emissions reductions)")
    plot(model.domain, f(model.controls.adapt) * model.economics.adapt_cost, label=L"$C_{\chi} f(\chi)$ (adaptation)")
    plot(model.domain, f(model.controls.geoeng) * model.economics.geoeng_cost, label=L"$C_{\lambda} f(\lambda)$ (geoengineering)")
    ylabel(L"cost of climate controls [10$^{12}$ \$ / year]")
    xlabel("year")
    xlim(model.domain[1],model.domain[end])
    grid(true)
    legend()
    annotate(s="d)",xy=(0,1.02),xycoords="axes fraction",fontsize=12)

    subplot(2,3,5)
    title("temperature change since 1850")
    plot_ensemble_statistics(
        ensemble, δT_baseline, domain,
        "C0", L"$T$ (baseline)"
    )
    plot_ensemble_statistics(
        ensemble, δT, domain,
        "C1", L"$T_{\varphi,\phi, \lambda}$ (controlled)"
    )
    plot_ensemble_statistics(
        ensemble, δT_no_geoeng, domain,
        "C2", L"$T_{\varphi,\phi}$ (controlled without geoengineering)"
    )
    plot(domain, 2.0.*ones(size(domain)), "k--", label="Paris Goal", alpha=0.5)
    plot(domain, 1.5.*ones(size(domain)), "k--", alpha=0.5)
    ylabel(L"warming [$^{\circ}$C]")
    xlabel("year")
    xlim([domain[1], domain[end]])
    grid(true)
    legend(loc="upper left")
    annotate(s="c)",xy=(0,1.02),xycoords="axes fraction",fontsize=12)

    subplot(2,3,6)
    title("discounted costs and benefits")
    plot_ensemble_statistics(
        ensemble, discounted_damage_cost_baseline, domain,
        "C0", "uncontrolled damages"
    )
    plot_ensemble_statistics(
        ensemble, discounted_net_cost, domain,
        "C1", "net cost (controlled damages + controls)"
    )
    plot_ensemble_statistics(
        ensemble, discounted_damage_cost, domain,
        "C2", "controlled damages"
    )
    plot_ensemble_statistics(
        ensemble, discounted_control_cost, domain,
        "C3", "cost of controls"
    )
    plot(model.domain,model.economics.β*(2.0^2).*ones(size(model.domain)),"k--", alpha=0.5)
    plot(model.domain,model.economics.β*(1.5^2).*ones(size(model.domain)),"k--", alpha=0.5)
    ylabel(L"discounted costs [10$^{12}$ \$ / year]")
    xlabel("year")
    xlim([domain[1], domain[end]])
    grid(true)
    legend()
    annotate(s="d)",xy=(0,1.02),xycoords="axes fraction",fontsize=12)
    
    tight_layout()
    return
end

