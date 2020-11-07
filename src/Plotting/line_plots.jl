rcParams = PyPlot.PyDict(PyPlot.matplotlib."rcParams")
rcParams["lines.linewidth"] = 2. # Change linewidth

function fill_past(m, ylims)
    domain_idx = (t(m) .> m.present_year)
    fill_between(
        t(m)[.~domain_idx],
        ones(size(t(m)[.~domain_idx])) * ylims[1] * 2.,
        ones(size(t(m)[.~domain_idx])) * ylims[2] * 2.,
        facecolor="b", alpha=0.1
    )
    ylim(ylims)
    return
end

function plot_emissions(m::ClimateModel)
    title("effective emissions")
    #fill_past(m, ylims)
    plot(t(m), zeros(size(t(m))), "k-", alpha=0.9)
    plot(t(m), effective_emissions(m), linestyle = "-", color="grey", label=L"$rq$ (no-policy baseline)")
    plot(t(m), effective_emissions(m, M=true), color="C0", label=L"$rq(1-M)$ (controlled)")
    plot(t(m), effective_emissions(m, M=true, R=true), color="C1", label=L"$rq(1-M) - rq_{0}R$ (controlled)")
    ylimit = maximum(effective_emissions(m)) * 1.1
    ylims = [-ylimit, ylimit]
    ylabel(L"effective CO$_{2e}$ emissions [ppm / yr]")
    xlim(t(m)[1],2200.)
    ylim(minimum(effective_emissions(m, M=true, R=true))-5.,1.1*maximum(effective_emissions(m)))
    xticks(t(m)[1]:40.:2200.)
    xlabel("year")
    grid(true, alpha=0.3)
    return
end

function plot_concentrations(m::ClimateModel)
    title("concentrations")
    #fill_past(m, ylims)
    plot(t(m), c(m), "-", color="gray", label=L"$c$ (no-policy baseline)")
    plot(t(m), c(m, M=true), color="C0", label=L"$c_{M}$")
    plot(t(m), c(m, M=true, R=true), color="C1", label=L"$c_{M,R}$")
    ylims = [0., maximum(c(m))*1.05]
    ylabel(L"CO$_{2e}$ concentration [ppm]")
    xlabel("year")
    xlim(t(m)[1],2200.)
    ylim(100., 1.05*maximum(c(m)))
    xticks(t(m)[1]:40.:2200.)
    grid(true, alpha=0.3)
    return
end

function plot_temperatures(m::ClimateModel)
    title("temperature change since 1850")
    #fill_past(m, ylims)
    plot(t(m),T(m), "-", color="gray", alpha=0.8, label=L"$T$ (no-policy baseline)")
    plot(t(m),T(m, M=true), color="C0", label=L"$T_{M}$")
    plot(t(m),T(m, M=true, R=true), color="C1", label=L"$T_{M,R}$")
    plot(t(m),T(m, M=true, R=true, G=true), color="C3", label=L"$T_{M,R,G}$")
    plot(t(m),T(m, M=true, R=true, G=true, A=true), color="C2", label=L"$T_{M,R,G,A}$")
    plot(t(m),1.5.*ones(size(t(m))),"k--", alpha=0.75)
    ylims = [0., maximum(T(m)) * 1.05]
    ylabel("temperature anomaly [°C]")
    xlabel("year")
    xlim(t(m)[1],2200.)
    xticks(t(m)[1]:40.:2200.)
    grid(true, alpha=0.3)
    legend()
    return
end

function plot_controls(m::ClimateModel)
    title("optimized control deployments")
    plot(t(m)[m.economics.baseline_emissions .> 0.], m.controls.mitigate[m.economics.baseline_emissions .> 0.], color="C0", label=L"$M$ (emissions mitigation)")
    plot(t(m), m.controls.remove, color="C1", label=L"$R$ (carbon dioxide removal)")
    plot(t(m), m.controls.adapt, color="C2", label=L"$A$ (adaptation)")
    plot(t(m), m.controls.geoeng, color="C3", label=L"$G$ (solar geoengineering)")
    ylims = [0., 1.]
    ylim([0,1.0])
    yticks(0.:0.2:1.0, 0:20:100)
    ylabel("control deployment [%]")
    xlabel("year")
    xlim(t(m)[1],2200.)
    xticks(t(m)[1]:40.:2200.)
    grid(true, alpha=0.3)
    return
end

function plot_benefits(m::ClimateModel; discounting=true)
    domain_idx = (t(m) .> m.domain.present_year)

    fill_between(
        t(m)[domain_idx],
        0 .*ones(size(t(m)))[domain_idx],
        net_benefit(m, discounting=discounting, M=true, R=true, G=true, A=true)[domain_idx],
        facecolor="grey", alpha=0.2
    )
    plot(t(m)[domain_idx], 0 .*ones(size(t(m)))[domain_idx], "-", color="gray", label="no-policy baseline")
    plot(t(m)[domain_idx], benefit(m, discounting=discounting, M=true, R=true, G=true, A=true)[domain_idx], color="C1", label="benefits (of avoided damages)")
    plot(t(m)[domain_idx], cost(m, discounting=discounting, M=true, R=true, G=true, A=true)[domain_idx], color="C3", label="costs (of climate controls)")
    plot(t(m)[domain_idx], net_benefit(m, discounting=discounting, M=true, R=true, G=true, A=true)[domain_idx], color="k", label="net benefits (benefits - costs)")
    ylabel(L"discounted costs and benefits [10$^{12}$ \$ / year]")
    xlabel("year")
    xlim(t(m)[1],2200.)
    xticks(t(m)[1]:40.:2200.)
    grid(true, alpha=0.3)
    title("cost-benefit analysis")
    return
end

function plot_damages(m::ClimateModel; discounting=true, percent_GWP=false)
    Enorm = deepcopy(E(m))/100.
    if ~percent_GWP; Enorm=1.; end;

    domain_idx = (t(m) .> m.domain.present_year)
    fill_between(
        t(m)[domain_idx],
        0 .*ones(size(t(m)))[domain_idx],
        (cost(m, discounting=discounting, M=true, R=true, G=true, A=true) ./ Enorm)[domain_idx],
        facecolor="C3", alpha=0.2
    )
    damages = damage(m, discounting=discounting, M=true, R=true, G=true, A=true)
    costs = cost(m, discounting=discounting, M=true, R=true, G=true, A=true)
    plot(t(m)[domain_idx], (damage(m, discounting=discounting) ./ Enorm)[domain_idx], color="gray", label="uncontrolled damages")
    plot(t(m)[domain_idx], ((damages .+ costs)./ Enorm)[domain_idx], color="k", label="net costs (controlled damages + controls)")
    plot(t(m)[domain_idx], (damages ./ Enorm)[domain_idx], color="C1", label="controlled damages")
    plot(t(m)[domain_idx], (costs ./ Enorm)[domain_idx], color="C3", label="cost of controls")

    Tgoal = 1.5
    plot(
        t(m)[domain_idx],
        (damage(m.economics.β, E(m), Tgoal, 0., discount=discount(m)) ./ Enorm)[domain_idx],
        "k--", alpha=0.75, label=L"damage threshold at 1.5°C with $A=0$"
    )

    ylim([0, maximum((damage(m, discounting=discounting) ./ Enorm)[domain_idx]) * 0.75])

    if ~percent_GWP;
        if ~discounting;
            ylabel(L"costs [10$^{12}$ \$ / year]");
        else;
            ylabel(L"discounted costs [10$^{12}$ \$ / year]");
        end
    else
        if ~discounting
            ylabel("costs [% GWP]")
        else
            ylabel("discounted costs [% GWP]")
            print("NOT YET SUPPORTED")
        end
    end

    xlabel("year")
    xlim(t(m)[1],2200.)
    xticks(t(m)[1]:40.:2200.)
    grid(true, alpha=0.3)
    title("costs of avoiding a damage threshold")
    legend()
    return
end

function plot_state(m::ClimateModel; new_figure=true, plot_legends=true)
    if new_figure
        fig, axs = subplots(2, 3, figsize=(14,8))
        axs = vcat(axs...)
    end

    sca(axs[1])
    plot_emissions(m)
    title("a)", loc="left")
    sca(axs[2])
    plot_concentrations(m)
    title("b)", loc="left")
    sca(axs[3])
    plot_temperatures(m)
    title("c)", loc="left")

    sca(axs[4])
    plot_controls(m)
    title("d)", loc="left")
    sca(axs[5])
    plot_benefits(m)
    title("e)", loc="left")
    sca(axs[6])
    plot_damages(m)
    title("f)", loc="left")

    if plot_legends;
        for ii in 1:6
            sca(axs[ii])
            if ii <= 2;
                legend(loc="lower left");
            else
                legend(loc="upper left");
            end
        end
    end
    tight_layout()

    return fig, axs
end
